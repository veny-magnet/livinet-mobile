// lib/core/models/user_profile.dart

class UserProfile {
  final int id;
  final String userId;
  final String username;
  final String phone;
  final String email;
  final String? emailVerifiedAt;
  final String country;
  final String status;
  final String? referralCode;
  final int points;
  final String? ktp;
  final String createdAt;
  final String updatedAt;
  final String? fcmToken;
  final String? province;
  final String? city;
  final String? nationalIdNumber;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? birthPlace;
  final String? birthDate;
  final String? gender;
  final String? address;
  final String? rt;
  final String? rw;
  final String? village;
  final String? district;
  final String? religion;
  final String? maritalStatus;
  final String? occupation;
  final String? citizenship;
  final String? validUntil;
  final int? whmcsId;
  final String? npwp;
  final int emailverified;
  final String datecreated;
  final String whmcsStatus;

  UserProfile({
    required this.id,
    required this.userId,
    required this.username,
    required this.phone,
    required this.email,
    this.emailVerifiedAt,
    required this.country,
    required this.status,
    this.referralCode,
    required this.points,
    this.ktp,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.province,
    this.city,
    this.nationalIdNumber,
    this.fullName,
    this.firstName,
    this.lastName,
    this.birthPlace,
    this.birthDate,
    this.gender,
    this.address,
    this.rt,
    this.rw,
    this.village,
    this.district,
    this.religion,
    this.maritalStatus,
    this.occupation,
    this.citizenship,
    this.validUntil,
    this.whmcsId,
    this.npwp,
    required this.emailverified,
    required this.datecreated,
    required this.whmcsStatus,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Generate username from first_name and last_name if username is not available
    String username = _safeGet(json, 'username', '');
    if (username.isEmpty) {
      final firstName = _safeGet(json, 'first_name', '');
      final lastName = _safeGet(json, 'last_name', '');
      username = '$firstName $lastName'.trim();
    }

    return UserProfile(
      id: _safeGet(json, 'id', 0),
      userId: _safeGet(json, 'user_id', ''),
      username: username,
      phone: _safeGet(json, 'phone', ''),
      email: _safeGet(json, 'email', ''),
      emailVerifiedAt: _safeGet(json, 'email_verified_at', null),
      country: _safeGet(json, 'country', ''),
      status: _safeGet(json, 'status', ''),
      referralCode: _safeGet(json, 'referral_code', null),
      points: _safeGet(json, 'points', 0),
      ktp: _safeGet(json, 'ktp', null),
      createdAt: _safeGet(json, 'created_at', ''),
      updatedAt: _safeGet(json, 'updated_at', ''),
      fcmToken: _safeGet(json, 'fcm_token', null),
      province: _safeGet(json, 'province', null),
      city: _safeGet(json, 'city', null),
      nationalIdNumber: _safeGet(json, 'national_id_number', null),
      fullName: _safeGet(json, 'full_name', null),
      firstName: _safeGet(json, 'first_name', null),
      lastName: _safeGet(json, 'last_name', null),
      birthPlace: _safeGet(json, 'birth_place', null),
      birthDate: _safeGet(json, 'birth_date', null),
      gender: _safeGet(json, 'gender', null),
      address: _safeGet(json, 'address', null),
      rt: _safeGet(json, 'rt', null),
      rw: _safeGet(json, 'rw', null),
      village: _safeGet(json, 'village', null),
      district: _safeGet(json, 'district', null),
      religion: _safeGet(json, 'religion', null),
      maritalStatus: _safeGet(json, 'marital_status', null),
      occupation: _safeGet(json, 'occupation', null),
      citizenship: _safeGet(json, 'citizenship', null),
      validUntil: _safeGet(json, 'valid_until', null),
      whmcsId: _safeGet(json, 'whmcs_id', null),
      npwp: _safeGet(json, 'npwp', null),
      emailverified: _safeGet(json, 'emailverified', 0),
      datecreated: _safeGet(json, 'datecreated', ''),
      whmcsStatus: _safeGet(json, 'whmcs_status', ''),
    );
  }

  /// Safe getter method to avoid "doesn't exist" errors
  static T _safeGet<T>(Map<String, dynamic> json, String key, T defaultValue) {
    try {
      if (json.containsKey(key)) {
        final value = json[key];
        if (value == null) return defaultValue;
        if (value is T) return value;

        // Type conversion for common cases
        if (T == String && value is! String) {
          return value.toString() as T;
        }
        if (T == int && value is String) {
          return int.tryParse(value) as T? ?? defaultValue;
        }
        if (T == int && value is double) {
          return value.toInt() as T;
        }

        return value as T;
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'phone': phone,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'country': country,
      'status': status,
      'referral_code': referralCode,
      'points': points,
      'ktp': ktp,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'fcm_token': fcmToken,
      'province': province,
      'city': city,
      'national_id_number': nationalIdNumber,
      'full_name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'birth_place': birthPlace,
      'birth_date': birthDate,
      'gender': gender,
      'address': address,
      'rt': rt,
      'rw': rw,
      'village': village,
      'district': district,
      'religion': religion,
      'marital_status': maritalStatus,
      'occupation': occupation,
      'citizenship': citizenship,
      'valid_until': validUntil,
      'whmcs_id': whmcsId,
      'npwp': npwp,
      'emailverified': emailverified,
      'datecreated': datecreated,
      'whmcs_status': whmcsStatus,
    };
  }
}
