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
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Open Sans',
          color: enabled ? Colors.black87 : Colors.grey,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontFamily: 'Open Sans',
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? const Color(0xFF4CB04C) : Colors.grey,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
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
                      'Address Detail',
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

              // Form Fields Area
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        const Text(
                          'Area Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          icon: Icons.location_city_outlined,
                          hintText: "Area Name",
                          controller: _areaController,
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          icon: Icons.home_outlined,
                          hintText: "Full Address",
                          controller: _addressController,
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'City',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          icon: Icons.location_city,
                          hintText: "City",
                          controller: _cityController,
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'State',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          icon: Icons.map_outlined,
                          hintText: "State",
                          controller: _stateController,
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'Postcode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          icon: Icons.local_post_office_outlined,
                          hintText: "Postcode",
                          controller: _postcodeController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'Country',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          icon: Icons.public_outlined,
                          hintText: "Country",
                          controller: _countryController,
                        ),
                        const SizedBox(height: 24),

                        // Space for bottom button
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Save Button
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _updateAddress,
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
                'Save Update',
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
