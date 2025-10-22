import '../models/order_detail_models.dart';
import 'app_logger.dart';
import 'base_api_service.dart';
import '../cache/cache_manager.dart';
import '../cache/cache.dart';

class OrderDetailsService {
  static const String CACHE_VERSION = '1.0.0';

  final BaseApiService _apiService;
  final _logger = AppLogger.instance;
  final _cacheManager = CacheManager.instance;

  OrderDetailsService({BaseApiService? apiService})
    : _apiService = apiService ?? BaseApiService();

  /// Get order details with optional user_address_id filter
  Future<OrderDetailsResponse?> getOrderDetails({
    required String userId,
    int? userAddressId,
    bool forceRefresh = false,
  }) async {
    try {
      // Create request object
      final request = OrderDetailsRequest(
        userId: userId,
        userAddressId: userAddressId,
      );

      final cacheKey = 'orders_${userId}_${userAddressId ?? "all"}';

      // Define cache configuration: 15 min fresh, 2 hours stale
      final cacheConfig = CacheConfig(
        maxAge: const Duration(minutes: 15),
        staleAge: const Duration(hours: 2),
        strategy: CacheStrategy.staleWhileRevalidate,
        version: CACHE_VERSION,
      );

      // Check cache first unless forced refresh
      if (!forceRefresh) {
        final cached = await _cacheManager.get<OrderDetailsResponse>(
          cacheKey,
          cacheConfig,
          (json) {
            return OrderDetailsResponse.fromJson(json);
          },
        );

        if (cached != null) {
          _logger.debug('Returning cached order details');
          return cached.data;
        }
      }

      _logger.debug(
        'Fetching order details for user: $userId, addressId: $userAddressId',
      );

      // Make API request
      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/orderdetails',
        queryParams: request.toQueryParams(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final orderDetailsResponse = OrderDetailsResponse.fromJson(
          response.data!,
        );

        // Cache the successful response
        await _cacheManager.set(cacheKey, {
          'orders': orderDetailsResponse.orders
              .map((order) => _orderDetailToJson(order))
              .toList(),
          'total': orderDetailsResponse.total,
        }, cacheConfig);

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

  /// Clear cached data
  Future<void> clearCache({String? userId, int? userAddressId}) async {
    try {
      if (userId != null && userAddressId != null) {
        final cacheKey = 'orders_${userId}_$userAddressId';
        await _cacheManager.invalidate(cacheKey);
        _logger.debug('Cleared order cache for: $cacheKey');
      } else if (userId != null) {
        // Clear all orders for this user
        await _cacheManager.invalidatePattern(r'^orders_' + userId + r'_.*');
        _logger.debug('Cleared all order cache for user: $userId');
      } else {
        // Clear all order cache
        await _cacheManager.invalidatePattern(r'^orders_.*');
        _logger.debug('Cleared all order cache');
      }
    } catch (e) {
      _logger.error('Error clearing order cache', e);
    }
  }

  /// Refresh order details data
  Future<OrderDetailsResponse?> refreshOrderDetails({
    required String userId,
    int? userAddressId,
  }) async {
    return await getOrderDetails(
      userId: userId,
      userAddressId: userAddressId,
      forceRefresh: true,
    );
  }

  // Helper method for JSON serialization
  Map<String, dynamic> _orderDetailToJson(OrderDetail order) {
    return {
      'id': order.id,
      'order_code': order.orderCode,
      'whmcs_order_id': order.whmcsOrderId,
      'whmcs_order_number': order.whmcsOrderNumber,
      'service_name': order.serviceName,
      'service_group': order.serviceGroup,
      'invoice_amount': order.invoiceAmount,
      'invoice_status': order.invoiceStatus,
      'service_status': order.serviceStatus,
      'invoice_details': {
        'subtotal': order.invoiceDetails.subtotal,
        'tax': order.invoiceDetails.tax,
        'tax_rate': order.invoiceDetails.taxRate,
        'tax2': order.invoiceDetails.tax2,
        'tax_rate2': order.invoiceDetails.taxRate2,
        'total': order.invoiceDetails.total,
        'balance': order.invoiceDetails.balance,
        'amount_paid': order.invoiceDetails.amountPaid,
        'credit': order.invoiceDetails.credit,
        'setup_fee': order.invoiceDetails.setupFee != null
            ? {
                'amount': order.invoiceDetails.setupFee!.amount,
                'description': order.invoiceDetails.setupFee!.description,
                'is_setup_fee_included':
                    order.invoiceDetails.setupFee!.isSetupFeeIncluded,
              }
            : null,
        'recurring_service': order.invoiceDetails.recurringService != null
            ? {
                'amount': order.invoiceDetails.recurringService!.amount,
                'description':
                    order.invoiceDetails.recurringService!.description,
              }
            : null,
        'cost_breakdown': order.invoiceDetails.costBreakdown != null
            ? {
                'setup_fee': order.invoiceDetails.costBreakdown!.setupFee,
                'service_cost': order.invoiceDetails.costBreakdown!.serviceCost,
                'subtotal_before_tax':
                    order.invoiceDetails.costBreakdown!.subtotalBeforeTax,
                'tax_amount': order.invoiceDetails.costBreakdown!.taxAmount,
                'total_amount': order.invoiceDetails.costBreakdown!.totalAmount,
              }
            : null,
      },
      'billing_cycle': order.billingCycle,
      'first_payment_amount': order.firstPaymentAmount,
      'recurring_amount': order.recurringAmount,
      'next_due_date': order.nextDueDate,
      'midtrans_data': {
        'midtrans_order_id': order.midtransData.midtransOrderId,
        'midtrans_token': order.midtransData.midtransToken,
        'midtrans_redirect_url': order.midtransData.midtransRedirectUrl,
        'midtrans_client_key': order.midtransData.midtransClientKey,
        'midtrans_merchant_base_url':
            order.midtransData.midtransMerchantBaseUrl,
        'payment_method': order.midtransData.paymentMethod,
        'payment_gateway_name': order.midtransData.paymentGatewayName,
      },
      'product_data': {
        'product_id': order.productData.productId,
        'product_name': order.productData.productName,
        'product_price': order.productData.productPrice,
        'product_detail': order.productData.productDetail,
        'subsplan_id': order.productData.subsplanId,
        'subsplan_name': order.productData.subsplanName,
      },
      'status_data': {
        'order_status': order.statusData.orderStatus,
        'payment_deadline': order.statusData.paymentDeadline,
        'is_paid': order.statusData.isPaid,
      },
      'address_details': {
        'address_id': order.addressDetails.addressId,
        'address': order.addressDetails.address,
        'area_name': order.addressDetails.areaName,
        'city_name': order.addressDetails.cityName,
        'state_name': order.addressDetails.stateName,
      },
      'custom_fields': order.customFields,
      'created_at': order.createdAt,
    };
  }
}
