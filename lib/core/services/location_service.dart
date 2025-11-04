import '../models/state_model.dart';
import '../models/city_model.dart';
import '../models/area_model.dart';
import 'base_api_service.dart';

class LocationService extends BaseApiService {
  /// Get all states/provinces
  /// GET /api/v1/get/states
  /// Cache: 7 days (provinces almost never change)
  Future<List<StateModel>> getStates({bool forceRefresh = false}) async {
    try {
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

  Future<List<CityModel>> getCities(
    int stateId, {
    bool forceRefresh = false,
  }) async {
    try {
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

  Future<List<AreaModel>> getAreas(
    int cityId, {
    bool forceRefresh = false,
  }) async {
    try {
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

  // Cache methods removed - no longer needed
}
