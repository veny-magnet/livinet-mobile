import 'package:flutter/material.dart';
import '../../core/services/address_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/address_card.dart';
import '../../core/widgets/app_button.dart';
import 'address_detail_screen.dart';
import 'add_address_screen.dart';

class AddressScreen extends StatefulWidget {
  final String userCode;

  const AddressScreen({super.key, required this.userCode});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool isLoading = true;
  List<UserAddress> addresses = [];
  List<dynamic> subscriptions = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Load addresses using userCode (UUID)
      final addressResult = await AddressService.instance.getUserAddresses(
        widget.userCode,
      );

      final subscriptionResult = await SubscriptionService.instance
          .getUserSubscriptions(widget.userCode);

      if (addressResult['success'] == true && addressResult['data'] != null) {
        setState(() {
          addresses = addressResult['data'] as List<UserAddress>;

          // Extract subscriptions list if available
          if (subscriptionResult['success'] == true &&
              subscriptionResult['data'] != null) {
            final subData = subscriptionResult['data'] as Map<String, dynamic>;
            subscriptions = subData['subscriptions'] as List<dynamic>? ?? [];
          }

          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = addressResult['message'] ?? 'Failed to load addresses';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading addresses: $e';
        isLoading = false;
      });
    }
  }

  void _showAddAddressDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAddressScreen(userCode: widget.userCode),
      ),
    ).then((_) {
      // Refresh list when returning from add screen
      _loadAddresses();
    });
  }

  void _showDeleteConfirmation(UserAddress address) {
    DialogHelper.showWarning(
      context,
      title: 'Delete Address',
      message:
          'Are you sure you want to delete this address?\n\n${address.stateName}\n${address.address}, ${address.cityName}, ${address.postcode}\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      onConfirm: () {
        _deleteAddress(address);
      },
    );
  }

  Future<void> _deleteAddress(UserAddress address) async {
    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final result = await AddressService.instance.deleteAddress(
        userCode: widget.userCode,
        code: address.code,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Handle result
      if (mounted) {
        if (result['success'] == true) {
          DialogHelper.showSuccess(
            context,
            title: 'Success',
            message: result['message'] ?? 'Address deleted successfully!',
            onConfirm: () {
              // Refresh list without closing the screen
              _loadAddresses();
            },
          );
        } else {
          DialogHelper.showError(
            context,
            title: 'Error',
            message: result['message'] ?? 'Failed to delete address',
            onConfirm: () {},
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (mounted) {
        DialogHelper.showError(
          context,
          title: 'Error',
          message: 'An error occurred: $e',
          onConfirm: () {
            Navigator.of(context).pop();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        titleSpacing: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'Open Sans',
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAddresses,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : addresses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: Colors.grey.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No addresses found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your first address to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadAddresses,
                child: ListView.builder(
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];

                    return AddressCard(
                      address: address,
                      subscriptions: subscriptions,
                      onDetailTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddressDetailScreen(
                              address: address,
                              onAddressDeleted: () {
                                // Refresh list when address is deleted
                                _loadAddresses();
                              },
                            ),
                          ),
                        ).then((_) {
                          // Refresh list when returning from detail screen
                          _loadAddresses();
                        });
                      },
                      onDeleteTap: () {
                        _showDeleteConfirmation(address);
                      },
                    );
                  },
                ),
              ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: AppButton(
          text: '+ Add New Address',
          onPressed: _showAddAddressDialog,
          isPrimary: true,
        ),
      ),
    );
  }
}
