import 'package:flutter/material.dart';
import '../../core/services/address_service.dart';
// ProductService import removed - no longer needed
import '../../core/services/location_service.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/models/state_model.dart';
import '../../core/models/city_model.dart';
import '../../core/models/area_model.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_dropdown_input.dart';
import '../../core/widgets/app_button.dart';

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
        DialogHelper.showSuccess(
          context,
          title: 'Success',
          message: result['message'] ?? 'Address added successfully!',
          onConfirm: () {
            Navigator.of(context).pop();
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
            'Add Address',
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // State Dropdown
              DropdownInput<StateModel>(
                icon: Icons.map_outlined,
                hintText: 'Province',
                value: _selectedState,
                items: _states.map((state) {
                  return DropdownMenuItem<StateModel>(
                    value: state,
                    child: Text(state.name),
                  );
                }).toList(),
                onChanged: (state) {
                  if (_isLoadingStates) return;
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
              const SizedBox(height: 16),

              // City Dropdown
              DropdownInput<CityModel>(
                icon: Icons.location_city_outlined,
                hintText: 'City',
                value: _selectedCity,
                items: _cities.map((city) {
                  return DropdownMenuItem<CityModel>(
                    value: city,
                    child: Text(city.name),
                  );
                }).toList(),
                onChanged: (city) {
                  if (_isLoadingCities || _selectedState == null) return;
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
              const SizedBox(height: 16),

              // Area Dropdown
              DropdownInput<AreaModel>(
                icon: Icons.my_location_outlined,
                hintText: 'Location',
                value: _selectedArea,
                items: _areas.map((area) {
                  return DropdownMenuItem<AreaModel>(
                    value: area,
                    child: Text(area.areaName),
                  );
                }).toList(),
                onChanged: (area) {
                  if (_isLoadingAreas || _selectedCity == null) return;
                  setState(() {
                    _selectedArea = area;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Address TextField
              TextInput(
                icon: Icons.home_outlined,
                hintText: 'Address',
                controller: _addressController,
              ),
              const SizedBox(height: 16),

              // Postcode TextField
              TextInput(
                icon: Icons.local_post_office_outlined,
                hintText: 'Postcode',
                controller: _postcodeController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),

              // Add Address Button
              AppButton(
                text: _isLoading ? 'Adding...' : 'Add Address',
                onPressed: _isLoading ? null : _addAddress,
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
