import 'address_service.dart';
import 'app_logger.dart';

class AddressManager {
  static AddressManager? _instance;
  UserAddress? _selectedAddress;
  List<Function(UserAddress?)> _listeners = [];
  final _logger = AppLogger.instance;

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
      _logger.error('Error loading default address', e);
    }
  }

  /// Get address by ID
  UserAddress? getAddressById(int addressId, List<UserAddress> addresses) {
    try {
      return addresses.firstWhere((addr) => addr.addressId == addressId);
    } catch (e) {
      return null;
    }
  }

  /// Update selected address by ID to ensure consistency
  void updateSelectedAddressById(int addressId, List<UserAddress> addresses) {
    final address = getAddressById(addressId, addresses);
    if (address != null) {
      setSelectedAddress(address);
    }
  }

  /// Get formatted location text
  String get formattedLocation {
    if (_selectedAddress == null) return 'Location not available';
    return '${_selectedAddress!.areaName}, ${_selectedAddress!.cityName}, ${_selectedAddress!.stateName}';
  }
}
