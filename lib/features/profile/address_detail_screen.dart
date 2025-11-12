import 'package:flutter/material.dart';
import '../../core/services/address_service.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_button.dart';

class AddressDetailScreen extends StatefulWidget {
  final UserAddress address;
  final VoidCallback? onAddressDeleted;

  const AddressDetailScreen({
    super.key,
    required this.address,
    this.onAddressDeleted,
  });

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

  void _updateAddress() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await AddressService.instance.updateAddress(
        userId: widget.address.userId,
        addressId: widget.address.addressId,
        address: _addressController.text.trim(),
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        DialogHelper.showSuccess(
          context,
          title: 'Success',
          message: result['message'] ?? 'Address updated successfully!',
          onConfirm: () {
            Navigator.of(context).pop(); // Go back to address list
          },
        );
      } else {
        DialogHelper.showError(
          context,
          title: 'Error',
          message: result['message'] ?? 'Failed to update address',
          onConfirm: () {
            Navigator.of(context).pop();
          },
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

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

  void _deleteAddress() async {
    // Show confirmation dialog
    DialogHelper.showWarning(
      context,
      title: 'Delete Address',
      message:
          'Are you sure you want to delete this address? This action cannot be undone.',
      onConfirm: () async {
        Navigator.of(context).pop(); // Close confirmation dialog

        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          final result = await AddressService.instance.deleteAddress(
            userId: widget.address.userId,
            addressId: widget.address.addressId,
          );

          // Close loading dialog
          if (mounted) {
            Navigator.of(context).pop();
          }

          if (result['success'] == true) {
            if (mounted) {
              DialogHelper.showSuccess(
                context,
                title: 'Success',
                message: result['message'] ?? 'Address deleted successfully!',
                onConfirm: () {
                  // Call callback to refresh parent screen
                  widget.onAddressDeleted?.call();

                  // Pop twice: once for dialog, once for this screen
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              );
            }
          } else {
            if (mounted) {
              DialogHelper.showError(
                context,
                title: 'Error',
                message: result['message'] ?? 'Failed to delete address',
                onConfirm: () {
                  Navigator.of(context).pop();
                },
              );
            }
          }
        } catch (e) {
          // Close loading dialog
          if (mounted) {
            Navigator.of(context).pop();
          }

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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            'Address Detail',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'Open Sans',
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Province (disabled)
            TextInput(
              icon: Icons.map_outlined,
              hintText: 'Province',
              controller: _stateController,
              enabled: false,
            ),
            const SizedBox(height: 16),

            // City (disabled)
            TextInput(
              icon: Icons.location_city_outlined,
              hintText: 'City',
              controller: _cityController,
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Location/Area (disabled)
            TextInput(
              icon: Icons.my_location_outlined,
              hintText: 'Location',
              controller: _areaController,
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Address (editable)
            TextInput(
              icon: Icons.home_outlined,
              hintText: 'Address',
              controller: _addressController,
            ),
            const SizedBox(height: 16),

            // Status (disabled)
            TextInput(
              icon: Icons.info_outline,
              hintText: 'Status',
              controller: TextEditingController(text: 'Active'),
              enabled: false,
            ),
            const SizedBox(height: 30),

            // Save Button
            AppButton(
              text: 'Save Changes',
              onPressed: _updateAddress,
              isPrimary: true,
            ),
            const SizedBox(height: 12),

            // Delete Button
            AppButton(
              text: 'Delete Address',
              onPressed: _deleteAddress,
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }
}
