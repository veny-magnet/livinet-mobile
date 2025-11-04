import 'package:flutter/material.dart';
import '../../core/services/address_service.dart';
// ProductService import removed - no longer needed
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/address_card.dart';
import 'address_detail_screen.dart';
import 'add_address_screen.dart';

class AddressScreen extends StatefulWidget {
  final String userId;

  const AddressScreen({super.key, required this.userId});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool isLoading = true;
  List<UserAddress> addresses = [];
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
      final result = await AddressService.instance.getUserAddresses(
        widget.userId,
      );

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          addresses = result['data'] as List<UserAddress>;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load addresses';
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
        builder: (context) => AddAddressScreen(userId: widget.userId),
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

  void _deleteAddress(UserAddress address) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await AddressService.instance.deleteAddress(
        userId: widget.userId,
        addressId: address.addressId,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        // Cache clearing removed - no longer needed

        DialogHelper.showSuccess(
          context,
          title: 'Success',
          message: result['message'] ?? 'Address deleted successfully!',
          onConfirm: () {
            // Refresh the address list
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
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      DialogHelper.showError(
        context,
        title: 'Error',
        message: 'An error occurred: $e',
        onConfirm: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CB04C), Color(0xFFF8D86E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar with Gradient Header Style
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      splashRadius: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'My Address',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Address List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
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
                                  onDetailTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddressDetailScreen(
                                              address: address,
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
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _showAddAddressDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CB04C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '+ Add New Address',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
