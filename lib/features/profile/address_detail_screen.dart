import 'package:flutter/material.dart';
import '../../core/services/address_service.dart';
import '../../core/services/product_service.dart';
import '../../core/widgets/confirmation_dialog.dart';

class AddressDetailScreen extends StatefulWidget {
  final UserAddress address;

  const AddressDetailScreen({super.key, required this.address});

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postcodeController;
  late TextEditingController _countryController;
  late TextEditingController _areaController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.address.address);
    _cityController = TextEditingController(text: widget.address.cityName);
    _stateController = TextEditingController(text: widget.address.stateName);
    _postcodeController = TextEditingController(text: widget.address.postcode);
    _countryController = TextEditingController(text: widget.address.country);
    _areaController = TextEditingController(text: widget.address.areaName);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _countryController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, fontFamily: 'Open Sans'),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontFamily: 'Open Sans',
          ),
        ),
      ),
    );
  }

  void _updateAddress() {
    // Clear product cache for this user when address is updated
    ProductService.instance.clearCache(userId: widget.address.userId);

    // Clear address cache to force refresh
    AddressService.instance.clearCache(userId: widget.address.userId);

    DialogHelper.showSuccess(
      context,
      title: 'Success',
      message: 'Address updated successfully!',
      onConfirm: () {
        Navigator.of(context).pop(); // Go back to address list
      },
    );
  }

  void _deleteAddress() {
    DialogHelper.showWarning(
      context,
      title: 'Delete Address',
      message:
          'Are you sure you want to delete this address?\nThis action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      onConfirm: () {
        // Clear product cache for this user when address is deleted
        ProductService.instance.clearCache(userId: widget.address.userId);

        // Clear address cache to force refresh
        AddressService.instance.clearCache(userId: widget.address.userId);

        DialogHelper.showSuccess(
          context,
          title: 'Success',
          message: 'Address deleted successfully!',
          onConfirm: () {
            Navigator.of(context).pop(); // Go back to address list
          },
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Form Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  const Text(
                    'Area Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    icon: Icons.location_city_outlined,
                    hintText: "Area Name",
                    controller: _areaController,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    icon: Icons.home_outlined,
                    hintText: "Full Address",
                    controller: _addressController,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'City',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    icon: Icons.location_city,
                    hintText: "City",
                    controller: _cityController,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'State',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    icon: Icons.map_outlined,
                    hintText: "State",
                    controller: _stateController,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Postcode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    icon: Icons.local_post_office_outlined,
                    hintText: "Postcode",
                    controller: _postcodeController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Country',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    icon: Icons.public_outlined,
                    hintText: "Country",
                    controller: _countryController,
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      // Update Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _updateAddress,
                          icon: const Icon(Icons.update_outlined, size: 18),
                          label: const Text('Update Address'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CB04C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Delete Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _deleteAddress,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete Address'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
