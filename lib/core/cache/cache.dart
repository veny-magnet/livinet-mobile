enum CacheStrategy {
  cacheFirst,
  networkFirst,
  cacheOnly,
  networkOnly,
  staleWhileRevalidate,
}

class CacheConfig {
  final Duration maxAge;
  final Duration staleAge;
  final bool persistToStorage;
  final CacheStrategy strategy;
  final String? version;

  const CacheConfig({
    this.maxAge = const Duration(minutes: 5),
    this.staleAge = const Duration(hours: 24),
    this.persistToStorage = true,
    this.strategy = CacheStrategy.staleWhileRevalidate,
    this.version,
  });
}

class CachedData<T> {
  final T data;
  final DateTime timestamp;
  final String version;
  final String etag;

  CachedData({
    required this.data,
    required this.timestamp,
    required this.version,
    required this.etag,
  });

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }

  bool isStale(Duration staleAge) {
    return DateTime.now().difference(timestamp) > staleAge;
  }

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'version': version,
    'etag': etag,
  };

  factory CachedData.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return CachedData<T>(
      data: fromJsonT(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      version: json['version'] ?? '1.0',
      etag: json['etag'] ?? '',
    );
  }
}
