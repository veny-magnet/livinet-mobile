import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'cache.dart';
import '../services/app_logger.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  static CacheManager get instance => _instance;
  CacheManager._internal();

  final _logger = AppLogger.instance;
  late Box<String> _cacheBox;
  late Box<String> _metadataBox;

  // In-memory cache for hot data
  final Map<String, dynamic> _memoryCache = {};

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      _cacheBox = await Hive.openBox<String>('api_cache_v2');
      _metadataBox = await Hive.openBox<String>('cache_metadata_v2');
      _isInitialized = true;
      _logger.info('Cache manager initialized');

      // Clean expired cache on startup
      await clearExpired();
    } catch (e) {
      _logger.error('Failed to initialize cache manager', e);
    }
  }

  /// Get cached data with strategy
  Future<CachedData<T>?> get<T>(
    String key,
    CacheConfig config,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (!_isInitialized) {
      _logger.warning('Cache manager not initialized');
      return null;
    }

    // 1. Check memory cache first (fastest)
    if (_memoryCache.containsKey(key)) {
      try {
        final cached = _memoryCache[key] as CachedData<T>;

        // Check version compatibility
        if (config.version != null && cached.version != config.version) {
          await invalidate(key);
          return null;
        }

        // Check if expired
        if (!cached.isExpired(config.maxAge)) {
          _logger.debug('Cache HIT (memory): $key');
          return cached;
        }
      } catch (e) {
        _logger.warning('Memory cache read error for $key', e);
        _memoryCache.remove(key);
      }
    }

    // 2. Check persistent storage
    if (config.persistToStorage) {
      try {
        final cachedJson = _cacheBox.get(key);
        if (cachedJson != null) {
          final json = jsonDecode(cachedJson) as Map<String, dynamic>;
          final cached = CachedData<T>.fromJson(
            json,
            (data) => fromJson(data as Map<String, dynamic>),
          );

          // Check version
          if (config.version != null && cached.version != config.version) {
            await invalidate(key);
            return null;
          }

          // Update memory cache
          _memoryCache[key] = cached;

          if (!cached.isExpired(config.maxAge)) {
            _logger.debug('Cache HIT (disk): $key');
            return cached;
          } else if (!cached.isStale(config.staleAge)) {
            _logger.debug('Cache STALE: $key');
            return cached; // Can be used with revalidation
          }
        }
      } catch (e) {
        _logger.error('Cache read error for $key', e);
        await invalidate(key);
      }
    }

    _logger.debug('Cache MISS: $key');
    return null;
  }

  /// Set cached data
  Future<void> set<T>(
    String key,
    T data,
    CacheConfig config, {
    String? etag,
  }) async {
    if (!_isInitialized) return;

    try {
      final cachedData = CachedData<T>(
        data: data,
        timestamp: DateTime.now(),
        version: config.version ?? '1.0',
        etag: etag ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Update memory cache
      _memoryCache[key] = cachedData;

      // Persist to storage
      if (config.persistToStorage) {
        final json = cachedData.toJson();
        await _cacheBox.put(key, jsonEncode(json));

        // Update metadata
        await _updateMetadata(key, config);

        _logger.debug('Cache SET: $key');
      }
    } catch (e) {
      _logger.error('Cache write error for $key', e);
    }
  }

  /// Invalidate specific cache
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    await _cacheBox.delete(key);
    await _metadataBox.delete(key);
    _logger.debug('Cache INVALIDATE: $key');
  }

  /// Invalidate by pattern
  Future<void> invalidatePattern(String pattern) async {
    final regex = RegExp(pattern);
    final keysToRemove = _cacheBox.keys
        .where((key) => regex.hasMatch(key.toString()))
        .toList();

    for (final key in keysToRemove) {
      await invalidate(key.toString());
    }

    _logger.info(
      'Invalidated ${keysToRemove.length} cache entries matching: $pattern',
    );
  }

  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _cacheBox.clear();
    await _metadataBox.clear();
    _logger.info('All cache cleared');
  }

  /// Clear expired cache
  Future<void> clearExpired() async {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final key in _metadataBox.keys) {
      try {
        final metadataJson = _metadataBox.get(key);
        if (metadataJson != null) {
          final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
          final timestamp = DateTime.parse(metadata['timestamp'] as String);
          final staleAge = Duration(seconds: metadata['staleAge'] as int);

          if (now.difference(timestamp) > staleAge) {
            keysToRemove.add(key.toString());
          }
        }
      } catch (e) {
        keysToRemove.add(key.toString());
      }
    }

    for (final key in keysToRemove) {
      await invalidate(key);
    }

    _logger.info('Cleared ${keysToRemove.length} expired cache entries');
  }

  Future<void> _updateMetadata(String key, CacheConfig config) async {
    final metadata = {
      'timestamp': DateTime.now().toIso8601String(),
      'maxAge': config.maxAge.inSeconds,
      'staleAge': config.staleAge.inSeconds,
      'version': config.version ?? '1.0',
    };
    await _metadataBox.put(key, jsonEncode(metadata));
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'memoryCache': _memoryCache.length,
      'persistentCache': _cacheBox.length,
      'totalSize': _cacheBox.values.fold<int>(
        0,
        (sum, item) => sum + item.length,
      ),
    };
  }
}
