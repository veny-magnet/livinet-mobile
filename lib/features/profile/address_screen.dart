import 'package:flutter/material.dart';
import '../../core/services/address_service.dart';
import '../../core/services/product_service.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/address_card.dart';
import 'address_detail_screen.dart';

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
    final addressController = TextEditingController();
    final postcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: postcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Postcode',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Note: City, State, and Area selection will be added in future updates.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                // Clear product cache for this user when new address is added
                ProductService.instance.clearCache(userId: widget.userId);

                // Clear address cache to force refresh
                AddressService.instance.clearCache(userId: widget.userId);

                DialogHelper.showSuccess(
                  context,
                  title: 'Success',
                  message: 'Address added successfully!',
                  onConfirm: () {
                    // Refresh the address list
                    _loadAddresses();
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CB04C),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: const Text(
          'Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Open Sans',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Add Address button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _showAddAddressDialog,
                  child: const Text(
                    'Add address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4CB04C),
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Address List
            Expanded(
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
                                      AddressDetailScreen(address: address),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
