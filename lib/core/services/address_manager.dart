import 'address_service.dart';

class AddressManager {
  static AddressManager? _instance;
  UserAddress? _selectedAddress;
  List<Function(UserAddress?)> _listeners = [];

  AddressManager._internal();

  static AddressManager get instance {
    _instance ??= AddressManager._internal();
    return _instance!;
  }

  /// Get currently selected address
  UserAddress? get selectedAddress => _selectedAddress;

  /// Get selected address ID
  int? get selectedAddressId => _selectedAddress?.addressId;

  /// Set selected address and notify all listeners
  void setSelectedAddress(UserAddress? address) {
    _selectedAddress = address;
    _notifyListeners();
  }

  /// Add listener for address changes
  void addListener(Function(UserAddress?) listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(Function(UserAddress?) listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners about address change
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_selectedAddress);
    }
  }

  /// Clear selected address
  void clearSelectedAddress() {
    _selectedAddress = null;
    _notifyListeners();
  }

  /// Load and set first address as default
  Future<void> loadDefaultAddress(String userId) async {
    try {
      final result = await AddressService.instance.getUserAddresses(userId);

      if (result['success'] == true && result['data'] != null) {
        final List<UserAddress> addresses = result['data'] as List<UserAddress>;
        if (addresses.isNotEmpty && _selectedAddress == null) {
          setSelectedAddress(addresses.first);
        }
      }
    } catch (e) {
      print('AddressManager - Error loading default address: $e');
    }
  }

  /// Get formatted location text
  String get formattedLocation {
    if (_selectedAddress == null) return 'Location not available';
    return '${_selectedAddress!.areaName}, ${_selectedAddress!.cityName}, ${_selectedAddress!.stateName}';
  }
}
