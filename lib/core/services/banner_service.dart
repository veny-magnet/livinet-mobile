import 'base_api_service.dart';
import 'app_logger.dart';

class Banner {
  final String name;
  final String path;
  final String? target;
  final String type;
  final String? promoStart;
  final String? promoEnd;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Banner({
    required this.name,
    required this.path,
    this.target,
    required this.type,
    this.promoStart,
    this.promoEnd,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      name: (json['name'] as String?)?.trim() ?? '',
      path: json['path'] ?? '',
      target: json['target'],
      type: json['type'] ?? '',
      promoStart: json['promostart'],
      promoEnd: json['promoend'],
      userId: json['userid'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'target': target,
      'type': type,
      'promostart': promoStart,
      'promoend': promoEnd,
      'userid': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if banner is still active based on promo dates
  bool get isActive {
    final now = DateTime.now();

    // If no start date, consider it active
    if (promoStart == null || promoStart!.isEmpty) {
      return true;
    }

    // If no end date, just check start date
    if (promoEnd == null || promoEnd!.isEmpty) {
      try {
        final start = DateTime.parse(promoStart!);
        return now.isAfter(start);
      } catch (e) {
        return true;
      }
    }

    // Check both start and end dates
    try {
      final start = DateTime.parse(promoStart!);
      final end = DateTime.parse(promoEnd!);
      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return true;
    }
  }
}

class BannerService {
  static final BannerService _instance = BannerService._internal();
  static BannerService get instance => _instance;

  BannerService._internal();

  final BaseApiService _apiService = BaseApiService();
  final _logger = AppLogger.instance;

  /// Get banners by type - NO CACHE, always fetch fresh
  Future<Map<String, dynamic>> getBanners({required String bannerType}) async {
    try {
      _logger.debug('Fetching banners for type: $bannerType');

      // Add additional headers for ngrok
      final additionalHeaders = {'ngrok-skip-browser-warning': 'true'};

      // Use BaseApiService for consistent API calls
      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/banner',
        queryParams: {'type': bannerType},
        headers: additionalHeaders,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final bannerList = responseData['banner'];

        if (bannerList == null || (bannerList is List && bannerList.isEmpty)) {
          _logger.debug('No banners found for type: $bannerType');
          return {
            'success': true,
            'data': <Banner>[],
            'message': 'No banners available',
          };
        }

        final bannersData = bannerList is List ? bannerList : [bannerList];

        final banners = bannersData
            .map((json) => Banner.fromJson(json as Map<String, dynamic>))
            .where((banner) => banner.isActive)
            .toList();

        _logger.debug('Successfully fetched ${banners.length} active banners');

        return {'success': true, 'data': banners, 'message': response.message};
      } else {
        _logger.warning('Failed to get banners: ${response.message}');
        return {
          'success': false,
          'message': response.message,
          'data': <Banner>[],
        };
      }
    } on ApiException catch (e) {
      String errorMessage;
      if (e.statusCode == 404) {
        errorMessage = 'Banner not found for this type';
      } else if (e.statusCode == 500) {
        errorMessage =
            'Server temporarily unavailable. Please try again later.';
      } else if (e.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.message.contains('No internet connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else {
        errorMessage = e.message;
      }

      _logger.error('ApiException in getBanners', e);
      return {'success': false, 'message': errorMessage, 'data': <Banner>[]};
    } catch (e) {
      _logger.error('Error in getBanners', e);
      return {
        'success': false,
        'message': 'Unexpected error occurred. Please try again.',
        'data': <Banner>[],
      };
    }
  }

  /// Get all banners regardless of type
  Future<Map<String, dynamic>> getAllBanners() async {
    try {
      _logger.debug('Fetching all banners');

      final additionalHeaders = {'ngrok-skip-browser-warning': 'true'};

      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/banner',
        headers: additionalHeaders,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final bannerList = responseData['banner'];

        if (bannerList == null || (bannerList is List && bannerList.isEmpty)) {
          _logger.debug('No banners found');
          return {
            'success': true,
            'data': <Banner>[],
            'message': 'No banners available',
          };
        }

        final bannersData = bannerList is List ? bannerList : [bannerList];

        final banners = bannersData
            .map((json) => Banner.fromJson(json as Map<String, dynamic>))
            .where((banner) => banner.isActive)
            .toList();

        _logger.debug(
          'Successfully fetched ${banners.length} total active banners',
        );

        return {'success': true, 'data': banners, 'message': response.message};
      } else {
        _logger.warning('Failed to get all banners: ${response.message}');
        return {
          'success': false,
          'message': response.message,
          'data': <Banner>[],
        };
      }
    } on ApiException catch (e) {
      String errorMessage;
      if (e.statusCode == 500) {
        errorMessage =
            'Server temporarily unavailable. Please try again later.';
      } else if (e.message.contains('No internet connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else {
        errorMessage = e.message;
      }

      _logger.error('ApiException in getAllBanners', e);
      return {'success': false, 'message': errorMessage, 'data': <Banner>[]};
    } catch (e) {
      _logger.error('Error in getAllBanners', e);
      return {
        'success': false,
        'message': 'Unexpected error occurred. Please try again.',
        'data': <Banner>[],
      };
    }
  }

  /// Get first banner of a specific type (useful for single banner displays)
  Future<Banner?> getFirstBanner({required String bannerType}) async {
    try {
      final result = await getBanners(bannerType: bannerType);

      if (result['success'] == true && result['data'] != null) {
        final banners = result['data'] as List<Banner>;
        if (banners.isNotEmpty) {
          _logger.debug(
            'Got first banner: ${banners.first.name} for type: $bannerType',
          );
          return banners.first;
        }
      }

      _logger.debug('No banners found for type: $bannerType');
      return null;
    } catch (e) {
      _logger.error('Error in getFirstBanner', e);
      return null;
    }
  }

  /// Format banner data for display
  Map<String, dynamic> formatBannerForDisplay(Banner banner) {
    return {
      'name': banner.name,
      'path': banner.path,
      'target': banner.target,
      'type': banner.type,
      'promoStart': banner.promoStart,
      'promoEnd': banner.promoEnd,
      'userId': banner.userId,
      'createdAt': banner.createdAt.toIso8601String(),
      'updatedAt': banner.updatedAt.toIso8601String(),
      'isActive': banner.isActive,
      'displayName': banner.name.isEmpty ? 'Banner' : banner.name,
    };
  }

  static dynamic getInsecureSSLNote() {
    // SSL verification is disabled at HttpOverrides level in main.dart
    // This applies to ALL network requests including banner image loading
    // Banner images loaded via Image.network() will use the disabled SSL
    return null;
  }
}
