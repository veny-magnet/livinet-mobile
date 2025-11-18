/// Service to persist signup form data across navigation
/// Prevents data loss when user navigates away and back to signup screen
class SignupFormService {
  static final SignupFormService _instance = SignupFormService._internal();

  factory SignupFormService() {
    return _instance;
  }

  SignupFormService._internal();

  // Form data storage
  final Map<String, dynamic> _formData = {
    'referralCode': '',
    'firstname': '',
    'lastname': '',
    'email': '',
    'phone': '',
    'password': '',
    'confirmPassword': '',
    'address': '',
    'postcode': '',
    'selectedState': null,
    'selectedCity': null,
    'selectedArea': null,
  };

  // Getters
  String get referralCode => _formData['referralCode'] ?? '';
  String get firstname => _formData['firstname'] ?? '';
  String get lastname => _formData['lastname'] ?? '';
  String get email => _formData['email'] ?? '';
  String get phone => _formData['phone'] ?? '';
  String get password => _formData['password'] ?? '';
  String get confirmPassword => _formData['confirmPassword'] ?? '';
  String get address => _formData['address'] ?? '';
  String get postcode => _formData['postcode'] ?? '';
  dynamic get selectedState => _formData['selectedState'];
  dynamic get selectedCity => _formData['selectedCity'];
  dynamic get selectedArea => _formData['selectedArea'];

  // Setters
  void setReferralCode(String value) => _formData['referralCode'] = value;
  void setFirstname(String value) => _formData['firstname'] = value;
  void setLastname(String value) => _formData['lastname'] = value;
  void setEmail(String value) => _formData['email'] = value;
  void setPhone(String value) => _formData['phone'] = value;
  void setPassword(String value) => _formData['password'] = value;
  void setConfirmPassword(String value) => _formData['confirmPassword'] = value;
  void setAddress(String value) => _formData['address'] = value;
  void setPostcode(String value) => _formData['postcode'] = value;
  void setSelectedState(dynamic value) => _formData['selectedState'] = value;
  void setSelectedCity(dynamic value) => _formData['selectedCity'] = value;
  void setSelectedArea(dynamic value) => _formData['selectedArea'] = value;

  /// Clear all form data (call after successful registration)
  void clearFormData() {
    _formData.clear();
    _formData.addAll({
      'referralCode': '',
      'firstname': '',
      'lastname': '',
      'email': '',
      'phone': '',
      'password': '',
      'confirmPassword': '',
      'address': '',
      'postcode': '',
      'selectedState': null,
      'selectedCity': null,
      'selectedArea': null,
    });
  }

  /// Get all form data as map
  Map<String, dynamic> getAllFormData() => Map.from(_formData);

  /// Check if form has any data
  bool hasFormData() {
    return firstname.isNotEmpty ||
        lastname.isNotEmpty ||
        email.isNotEmpty ||
        phone.isNotEmpty ||
        address.isNotEmpty ||
        postcode.isNotEmpty;
  }
}
