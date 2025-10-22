import '../models/state_model.dart';
import '../models/city_model.dart';
import '../models/area_model.dart';
import 'base_api_service.dart';
import '../cache/cache_manager.dart';
import '../cache/cache.dart';

class LocationService extends BaseApiService {
  final _cacheManager = CacheManager.instance;
  static const String CACHE_VERSION = '1.0.0';

  /// Get all states/provinces
  /// GET /api/v1/get/states
  /// Cache: 7 days (provinces almost never change)
  Future<List<StateModel>> getStates({bool forceRefresh = false}) async {
    try {
      final cacheKey = 'location_states';

      // Define cache configuration: 7 days fresh, 30 days stale
      final cacheConfig = CacheConfig(
        maxAge: const Duration(days: 7),
        staleAge: const Duration(days: 30),
        strategy: CacheStrategy.cacheFirst,
        version: CACHE_VERSION,
      );

      // Check cache first unless force refresh
      if (!forceRefresh) {
        final cached = await _cacheManager.get<List<StateModel>>(
          cacheKey,
          cacheConfig,
          (json) {
            final statesData = json['states'] as List;
            return statesData
                .map(
                  (item) => StateModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          },
        );

        if (cached != null) {
          return cached.data;
        }
      }

      final response = await get<List<StateModel>>(
        '/get/states',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => StateModel.fromJson(item)).toList();
          }
          throw ApiException('Invalid data format for states');
        },
      );

      if (response.success && response.data != null) {
        // Store in cache
        await _cacheManager.set(cacheKey, {
          'states': response.data!.map((s) => s.toJson()).toList(),
        }, cacheConfig);

        return response.data!;
      } else {
        throw ApiException(response.message);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to fetch states: $e');
    }
  }

  /// Get cities by state
  /// GET /api/v1/get/cities?state_id={id}
  /// Cache: 7 days (cities rarely change)
  Future<List<CityModel>> getCities(
    int stateId, {
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'location_cities_$stateId';

      // Define cache configuration: 7 days fresh, 30 days stale
      final cacheConfig = CacheConfig(
        maxAge: const Duration(days: 7),
        staleAge: const Duration(days: 30),
        strategy: CacheStrategy.cacheFirst,
        version: CACHE_VERSION,
      );

      // Check cache first unless force refresh
      if (!forceRefresh) {
        final cached = await _cacheManager.get<List<CityModel>>(
          cacheKey,
          cacheConfig,
          (json) {
            final citiesData = json['cities'] as List;
            return citiesData
                .map((item) => CityModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );

        if (cached != null) {
          return cached.data;
        }
      }

      final response = await get<List<CityModel>>(
        '/get/cities',
        queryParams: {'state_id': stateId.toString()},
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => CityModel.fromJson(item)).toList();
          }
          throw ApiException('Invalid data format for cities');
        },
      );

      if (response.success && response.data != null) {
        // Store in cache
        await _cacheManager.set(cacheKey, {
          'cities': response.data!.map((c) => c.toJson()).toList(),
        }, cacheConfig);

        return response.data!;
      } else {
        throw ApiException(response.message);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to fetch cities: $e');
    }
  }

  /// Get areas by city
  /// GET /api/v1/get/areas?city_id={id}
  /// Cache: 7 days (areas rarely change)
  Future<List<AreaModel>> getAreas(
    int cityId, {
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'location_areas_$cityId';

      // Define cache configuration: 7 days fresh, 30 days stale
      final cacheConfig = CacheConfig(
        maxAge: const Duration(days: 7),
        staleAge: const Duration(days: 30),
        strategy: CacheStrategy.cacheFirst,
        version: CACHE_VERSION,
      );

      // Check cache first unless force refresh
      if (!forceRefresh) {
        final cached = await _cacheManager.get<List<AreaModel>>(
          cacheKey,
          cacheConfig,
          (json) {
            final areasData = json['areas'] as List;
            return areasData
                .map((item) => AreaModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );

        if (cached != null) {
          return cached.data;
        }
      }

      final response = await get<List<AreaModel>>(
        '/get/areas',
        queryParams: {'city_id': cityId.toString()},
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => AreaModel.fromJson(item)).toList();
          }
          throw ApiException('Invalid data format for areas');
        },
      );

      if (response.success && response.data != null) {
        // Store in cache
        await _cacheManager.set(cacheKey, {
          'areas': response.data!.map((a) => a.toJson()).toList(),
        }, cacheConfig);

        return response.data!;
      } else {
        throw ApiException(response.message);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to fetch areas: $e');
    }
  }

  /// Clear location cache
  Future<void> clearCache() async {
    await _cacheManager.invalidatePattern(r'^location_.*');
  }
}
