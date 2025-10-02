import 'package:flutter/material.dart';
import '../../core/services/location_service.dart';
import '../../core/models/state_model.dart';
import '../../core/models/city_model.dart';
import '../../core/models/area_model.dart';

/// Example widget showing how to use LocationService for registration dropdown
class LocationDropdownExample extends StatefulWidget {
  const LocationDropdownExample({super.key});

  @override
  State<LocationDropdownExample> createState() => _LocationDropdownExampleState();
}

class _LocationDropdownExampleState extends State<LocationDropdownExample> {
  final LocationService _locationService = LocationService();
  
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  List<AreaModel> _areas = [];
  
  StateModel? _selectedState;
  CityModel? _selectedCity;
  AreaModel? _selectedArea;
  
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  bool _isLoadingAreas = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    setState(() => _isLoadingStates = true);
    
    try {
      final states = await _locationService.getStates();
      setState(() {
        _states = states;
        _isLoadingStates = false;
      });
    } catch (e) {
      setState(() => _isLoadingStates = false);
      _showError('Failed to load states: $e');
    }
  }

  Future<void> _loadCities(int stateId) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _areas = [];
      _selectedCity = null;
      _selectedArea = null;
    });
    
    try {
      final cities = await _locationService.getCities(stateId);
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() => _isLoadingCities = false);
      _showError('Failed to load cities: $e');
    }
  }

  Future<void> _loadAreas(int cityId) async {
    setState(() {
      _isLoadingAreas = true;
      _areas = [];
      _selectedArea = null;
    });
    
    try {
      final areas = await _locationService.getAreas(cityId);
      setState(() {
        _areas = areas;
        _isLoadingAreas = false;
      });
    } catch (e) {
      setState(() => _isLoadingAreas = false);
      _showError('Failed to load areas: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Selection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // State Dropdown
            const Text('State/Province:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _isLoadingStates
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<StateModel>(
                    value: _selectedState,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select State',
                    ),
                    items: _states.map((state) {
                      return DropdownMenuItem(
                        value: state,
                        child: Text(state.name),
                      );
                    }).toList(),
                    onChanged: (StateModel? value) {
                      setState(() => _selectedState = value);
                      if (value != null) {
                        _loadCities(value.id);
                      }
                    },
                  ),
            
            const SizedBox(height: 20),
            
            // City Dropdown
            const Text('City:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _isLoadingCities
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<CityModel>(
                    value: _selectedCity,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select City',
                    ),
                    items: _cities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city.name),
                      );
                    }).toList(),
                    onChanged: _selectedState == null
                        ? null
                        : (CityModel? value) {
                            setState(() => _selectedCity = value);
                            if (value != null) {
                              _loadAreas(value.id);
                            }
                          },
                  ),
            
            const SizedBox(height: 20),
            
            // Area Dropdown
            const Text('Area:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _isLoadingAreas
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<AreaModel>(
                    value: _selectedArea,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select Area',
                    ),
                    items: _areas.map((area) {
                      return DropdownMenuItem(
                        value: area,
                        child: Text(area.areaName),
                      );
                    }).toList(),
                    onChanged: _selectedCity == null
                        ? null
                        : (AreaModel? value) {
                            setState(() => _selectedArea = value);
                          },
                  ),
            
            const SizedBox(height: 30),
            
            // Display Selected Values
            if (_selectedState != null || _selectedCity != null || _selectedArea != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selected Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_selectedState != null)
                      Text('State: ${_selectedState!.name} (ID: ${_selectedState!.id})'),
                    if (_selectedCity != null)
                      Text('City: ${_selectedCity!.name} (ID: ${_selectedCity!.id})'),
                    if (_selectedArea != null)
                      Text('Area: ${_selectedArea!.areaName} (ID: ${_selectedArea!.id})'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}