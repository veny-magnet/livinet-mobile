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

  /// Get selected address code
  String? get selectedAddressCode => _selectedAddress?.code;

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

  /// Load and set first address as default menggunakan userCode (UUID)
  Future<void> loadDefaultAddress(String userCode) async {
    try {
      final result = await AddressService.instance.getUserAddresses(userCode);

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

  /// Get address by code
  UserAddress? getAddressByCode(String code, List<UserAddress> addresses) {
    try {
      return addresses.firstWhere((addr) => addr.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Update selected address by code to ensure consistency
  void updateSelectedAddressByCode(String code, List<UserAddress> addresses) {
    final address = getAddressByCode(code, addresses);
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
