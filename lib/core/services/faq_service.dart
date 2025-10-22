import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'app_logger.dart';
import '../cache/cache_manager.dart';
import '../cache/cache.dart';

class FAQService {
  static final _config = AppConfig.instance;
  static String get baseUrl => _config.baseUrl;
  static final _logger = AppLogger.instance;
  static final _cacheManager = CacheManager.instance;

  static const String CACHE_VERSION = '1.0.0';

  static Future<List<FAQ>> getFAQs({bool forceRefresh = false}) async {
    _logger.debug('FAQService - Getting FAQs, forceRefresh: $forceRefresh');

    final cacheKey = 'faqs';

    // Define cache configuration: 24 hours fresh, 7 days stale
    final cacheConfig = CacheConfig(
      maxAge: const Duration(hours: 24),
      staleAge: const Duration(days: 7),
      strategy: CacheStrategy.cacheFirst,
      version: CACHE_VERSION,
    );

    // Check cache first unless force refresh
    if (!forceRefresh) {
      final cached = await _cacheManager.get<List<FAQ>>(cacheKey, cacheConfig, (
        json,
      ) {
        final faqsData = json['faqs'] as List;
        return faqsData
            .map((item) => FAQ.fromJson(item as Map<String, dynamic>))
            .toList();
      });

      if (cached != null) {
        _logger.debug('Returning cached FAQs: ${cached.data.length} items');
        return cached.data;
      }
    }

    try {
      _logger.debug('FAQService - Making API call to: $baseUrl/get/faq');
      final response = await http.get(
        Uri.parse('$baseUrl/get/faq'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      _logger.debug('Response status: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        _logger.debug('Parsed JSON: $jsonResponse');

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> faqsJson = jsonResponse['data']['faqs'];
          _logger.debug('FAQs JSON: $faqsJson');
          _logger.debug('FAQs count: ${faqsJson.length}');

          final faqList = faqsJson.map((json) => FAQ.fromJson(json)).toList();
          _logger.debug('Converted FAQ objects: ${faqList.length}');

          // Store in cache
          await _cacheManager.set(cacheKey, {
            'faqs': faqList.map((f) => f.toJson()).toList(),
          }, cacheConfig);

          return faqList;
        } else {
          _logger.warning('API response not successful or no data');
          throw Exception('Failed to load FAQs: ${jsonResponse['message']}');
        }
      } else {
        _logger.warning('HTTP error: ${response.statusCode}');
        throw Exception('Failed to load FAQs: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Exception caught', e);

      // Try to return any cached data (even if expired) on error
      try {
        final expiredCacheConfig = CacheConfig(
          maxAge: const Duration(days: 365), // Accept any cache
          staleAge: const Duration(days: 365),
          strategy: CacheStrategy.cacheFirst,
          version: CACHE_VERSION,
        );

        final cached = await _cacheManager.get<List<FAQ>>(
          cacheKey,
          expiredCacheConfig,
          (json) {
            final faqsData = json['faqs'] as List;
            return faqsData
                .map((item) => FAQ.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );

        if (cached != null) {
          _logger.info(
            'Returning cached FAQs due to error: ${cached.data.length} items',
          );
          return cached.data;
        }
      } catch (cacheError) {
        _logger.error('Failed to retrieve expired cache', cacheError);
      }

      throw Exception('Error fetching FAQs: $e');
    }
  }

  static Future<void> clearCache() async {
    await _cacheManager.invalidate('faqs');
  }

  static Future<Map<String, dynamic>> getCacheInfo() async {
    final cached = await _cacheManager.get<List<FAQ>>(
      'faqs',
      CacheConfig(
        maxAge: const Duration(hours: 24),
        staleAge: const Duration(days: 7),
        strategy: CacheStrategy.cacheFirst,
        version: CACHE_VERSION,
      ),
      (json) {
        final faqsData = json['faqs'] as List;
        return faqsData
            .map((item) => FAQ.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );

    return {
      'hasCachedData': cached != null,
      'lastFetch': cached?.timestamp.toIso8601String(),
      'cacheValid':
          cached != null && !cached.isExpired(const Duration(hours: 24)),
      'itemCount': cached?.data.length ?? 0,
    };
  }
}

class FAQ {
  final int faqID;
  final String faqTittle;
  final String faqDesc;
  final String createdAt;
  final String updatedAt;

  FAQ({
    required this.faqID,
    required this.faqTittle,
    required this.faqDesc,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      faqID: json['faqID'] ?? 0,
      faqTittle: json['faqTittle'] ?? '',
      faqDesc: json['faqDesc'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faqID': faqID,
      'faqTittle': faqTittle,
      'faqDesc': faqDesc,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
