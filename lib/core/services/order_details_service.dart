import '../models/order_detail_models.dart';
import 'app_logger.dart';
import 'base_api_service.dart';

class OrderDetailsService {
  static final OrderDetailsService _instance = OrderDetailsService._internal();
  static OrderDetailsService get instance => _instance;
  OrderDetailsService._internal() : _apiService = BaseApiService();

  final BaseApiService _apiService;
  final _logger = AppLogger.instance;

  /// NO CACHE - Always fetch fresh data from server
  Future<OrderDetailsResponse?> getOrderDetails({
    required String userId,
    int? userAddressId,
    bool forceRefresh = false, // Keep parameter for backward compatibility
  }) async {
    try {
      // Create request object
      final request = OrderDetailsRequest(
        userId: userId,
        userAddressId: userAddressId,
      );

      _logger.debug(
        'Fetching order details for user: $userId, addressId: $userAddressId',
      );

      // Make API request - NO CACHE, always fresh
      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/orderdetails',
        queryParams: request.toQueryParams(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final orderDetailsResponse = OrderDetailsResponse.fromJson(
          response.data!,
        );

        _logger.debug(
          'Successfully fetched ${orderDetailsResponse.orders.length} orders',
        );
        return orderDetailsResponse;
      } else {
        _logger.warning('Order details API error: ${response.message}');
        return null;
      }
    } catch (e, stackTrace) {
      _logger.error('Error fetching order details', e, stackTrace);
      return null;
    }
  }

  /// Get single order by order ID
  Future<OrderDetail?> getOrderById({
    required String userId,
    required int orderId,
    int? userAddressId,
  }) async {
    try {
      final response = await getOrderDetails(
        userId: userId,
        userAddressId: userAddressId,
      );

      if (response != null) {
        final order = response.orders
            .where((order) => order.id == orderId)
            .firstOrNull;
        if (order != null) {
          _logger.debug('Found order with ID: $orderId');
          return order;
        } else {
          _logger.warning('Order with ID $orderId not found');
        }
      }
      return null;
    } catch (e) {
      _logger.error('Error getting order by ID', e);
      return null;
    }
  }

  /// Get orders by status (Paid/Unpaid)
  Future<List<OrderDetail>> getOrdersByStatus({
    required String userId,
    required String status,
    int? userAddressId,
  }) async {
    try {
      final response = await getOrderDetails(
        userId: userId,
        userAddressId: userAddressId,
      );

      if (response != null) {
        final filteredOrders = response.orders
            .where(
              (order) =>
                  order.invoiceStatus.toLowerCase() == status.toLowerCase(),
            )
            .toList();

        _logger.debug(
          'Found ${filteredOrders.length} orders with status: $status',
        );
        return filteredOrders;
      }
      return [];
    } catch (e) {
      _logger.error('Error filtering orders by status', e);
      return [];
    }
  }

  /// Get unpaid orders for bill display
  Future<List<OrderDetail>> getUnpaidOrders({
    required String userId,
    int? userAddressId,
  }) async {
    return await getOrdersByStatus(
      userId: userId,
      status: 'unpaid',
      userAddressId: userAddressId,
    );
  }

  /// Get paid orders for history
  Future<List<OrderDetail>> getPaidOrders({
    required String userId,
    int? userAddressId,
  }) async {
    return await getOrdersByStatus(
      userId: userId,
      status: 'paid',
      userAddressId: userAddressId,
    );
  }

  /// Refresh order details data (alias for getOrderDetails with backward compatibility)
  Future<OrderDetailsResponse?> refreshOrderDetails({
    required String userId,
    int? userAddressId,
  }) async {
    return await getOrderDetails(
      userId: userId,
      userAddressId: userAddressId,
      forceRefresh: true, // Not used internally, but kept for API compatibility
    );
  }
}
