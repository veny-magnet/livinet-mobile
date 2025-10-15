import '../services/base_api_service.dart';
import '../models/bill_models.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  static SubscriptionService get instance => _instance;

  SubscriptionService._internal();

  final BaseApiService _apiService = BaseApiService();

  Future<Map<String, dynamic>> getUserSubscriptions(String userId) async {
    try {
      print('SubscriptionService: Fetching subscriptions for userId: $userId');

      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/subscriptions',
        queryParams: {
          'user_id': userId,
          // Remove status filter to get all subscriptions
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      print('SubscriptionService: Raw API response: $response');
      print('SubscriptionService: Response success: ${response.success}');
      print('SubscriptionService: Response data: ${response.data}');

      if (response.success && response.data != null) {
        return {
          'success': true,
          'message': response.message,
          'data': response.data,
        };
      } else {
        return {'success': false, 'message': response.message, 'data': null};
      }
    } catch (e) {
      print('SubscriptionService: Exception occurred: $e');
      return {
        'success': false,
        'message': 'Failed to get subscriptions: $e',
        'data': null,
      };
    }
  }

  // Convert subscription data to BillHistory format for compatibility
  List<BillHistory> convertSubscriptionsToBills(
    Map<String, dynamic> subscriptionData,
  ) {
    try {
      final List<dynamic> subscriptions =
          subscriptionData['subscriptions'] ?? [];

      return subscriptions.map((sub) {
        return BillHistory(
          amount: sub['monthlyPrice']?.toString() ?? '0',
          paymentStatus: sub['status'] == 'active' ? 'PAID' : 'UNPAID',
          invoiceStatusWhmcs: sub['status'] == 'active' ? 'paid' : 'unpaid',
          paymentDate: sub['status'] == 'active'
              ? DateTime.now().toString()
              : null,
          invoiceId: sub['subsplanID']?.toString() ?? '',
          midtransOrderId: 'SUB-${sub['subsplanID'] ?? 'unknown'}',
          userAddressId: sub['address']?['addressId'],
          createdAt: sub['registrationDate'] ?? DateTime.now().toString(),
        );
      }).toList();
    } catch (e) {
      print('Error converting subscriptions to bills: $e');
      return [];
    }
  }
}
