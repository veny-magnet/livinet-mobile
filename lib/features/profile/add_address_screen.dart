import 'package:flutter/material.dart';
import '../../core/services/address_service.dart';
import '../../core/services/product_service.dart';
import '../../core/services/location_service.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/models/state_model.dart';
import '../../core/models/city_model.dart';
import '../../core/models/area_model.dart';

class AddAddressScreen extends StatefulWidget {
  final String userId;

  const AddAddressScreen({super.key, required this.userId});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _postcodeController;

  final LocationService _locationService = LocationService();

  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  List<AreaModel> _areas = [];

  StateModel? _selectedState;
  CityModel? _selectedCity;
  AreaModel? _selectedArea;

  bool _isLoading = false;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  bool _isLoadingAreas = false;
  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _postcodeController = TextEditingController();
    _loadStates();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadStates() async {
    setState(() {
      _isLoadingStates = true;
    });

    try {
      final states = await _locationService.getStates();
      setState(() {
        _states = states;
        _isLoadingStates = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStates = false;
      });
      if (mounted) {
        DialogHelper.showError(
          context,
          title: 'Error',
          message: 'Failed to load states: $e',
          onConfirm: () {},
        );
      }
    }
  }

  Future<void> _loadCities(int stateId) async {
    setState(() {
      _isLoadingCities = true;
      _selectedCity = null;
      _selectedArea = null;
      _cities = [];
      _areas = [];
    });

    try {
      final cities = await _locationService.getCities(stateId);
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCities = false;
      });
      if (mounted) {
        DialogHelper.showError(
          context,
          title: 'Error',
          message: 'Failed to load cities: $e',
          onConfirm: () {},
        );
      }
    }
  }

  Future<void> _loadAreas(int cityId) async {
    setState(() {
      _isLoadingAreas = true;
      _selectedArea = null;
      _areas = [];
    });

    try {
      final areas = await _locationService.getAreas(cityId);
      setState(() {
        _areas = areas;
        _isLoadingAreas = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAreas = false;
      });
      if (mounted) {
        DialogHelper.showError(
          context,
          title: 'Error',
          message: 'Failed to load areas: $e',
          onConfirm: () {},
        );
      }
    }
  }

  Widget _buildTextField({
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        maxLines: maxLines,
        validator: validator,
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

  Widget _buildDropdown<T>({
    required IconData icon,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) getDisplayText,
    required void Function(T?) onChanged,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontFamily: 'Open Sans',
          ),
          prefixIcon: isLoading
              ? Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(12),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: const Color(0xFF4CB04C), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              getDisplayText(item),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Open Sans',
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: isLoading ? null : onChanged,
        validator: (value) {
          if (value == null) {
            return 'Please select $hint';
          }
          return null;
        },
      ),
    );
  }

  void _addAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedArea == null) {
      DialogHelper.showError(
        context,
        title: 'Error',
        message: 'Please select state, city and area first',
        onConfirm: () {},
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AddressService.instance.addAddress(
        userId: widget.userId,
        address: _addressController.text.trim(),
        cityId: _selectedCity!.id,
        stateId: _selectedState!.id,
        areaId: _selectedArea!.id,
        postcode: _postcodeController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Clear product cache for this user when new address is added
        ProductService.instance.clearCache(userId: widget.userId);

        DialogHelper.showSuccess(
          context,
          title: 'Success',
          message: result['message'] ?? 'Address added successfully!',
          onConfirm: () {
            Navigator.of(context).pop(); // Go back to address list
          },
        );
      } else {
        DialogHelper.showError(
          context,
          title: 'Error',
          message: result['message'] ?? 'Failed to add address',
          onConfirm: () {},
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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
                      'Add New Address',
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // State Dropdown
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
                          _buildDropdown<StateModel>(
                            icon: Icons.map_outlined,
                            hint: 'Select State',
                            value: _selectedState,
                            items: _states,
                            getDisplayText: (state) => state.name,
                            isLoading: _isLoadingStates,
                            onChanged: (state) {
                              setState(() {
                                _selectedState = state;
                                _selectedCity = null;
                                _selectedArea = null;
                                _cities = [];
                                _areas = [];
                              });
                              if (state != null) {
                                _loadCities(state.id);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // City Dropdown
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
                          _buildDropdown<CityModel>(
                            icon: Icons.location_city,
                            hint: 'Select City',
                            value: _selectedCity,
                            items: _cities,
                            getDisplayText: (city) => city.name,
                            isLoading: _isLoadingCities,
                            onChanged: (city) {
                              setState(() {
                                _selectedCity = city;
                                _selectedArea = null;
                                _areas = [];
                              });
                              if (city != null) {
                                _loadAreas(city.id);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Area Dropdown
                          const Text(
                            'Area',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontFamily: 'Open Sans',
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildDropdown<AreaModel>(
                            icon: Icons.location_city_outlined,
                            hint: 'Select Area',
                            value: _selectedArea,
                            items: _areas,
                            getDisplayText: (area) => area.areaName,
                            isLoading: _isLoadingAreas,
                            onChanged: (area) {
                              setState(() {
                                _selectedArea = area;
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            'Full Address',
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
                            hintText: "Enter your full address",
                            controller: _addressController,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Address is required';
                              }
                              return null;
                            },
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
                            hintText: "Enter postcode",
                            controller: _postcodeController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Postcode is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Info Note
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Location selection (City, State, Area) will be implemented in future updates. Currently using default location.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontFamily: 'Open Sans',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Space for bottom button
                          const SizedBox(height: 100),
                        ],
                      ),
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
              onPressed: _isLoading ? null : _addAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CB04C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Add Address',
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
