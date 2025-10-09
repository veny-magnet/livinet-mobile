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
    return UserProfile(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      country: json['country'] ?? '',
      status: json['status'] ?? '',
      referralCode: json['referral_code'],
      points: json['points'] ?? 0,
      ktp: json['ktp'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      fcmToken: json['fcm_token'],
      province: json['province'],
      city: json['city'],
      nationalIdNumber: json['national_id_number'],
      fullName: json['full_name'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      birthPlace: json['birth_place'],
      birthDate: json['birth_date'],
      gender: json['gender'],
      address: json['address'],
      rt: json['rt'],
      rw: json['rw'],
      village: json['village'],
      district: json['district'],
      religion: json['religion'],
      maritalStatus: json['marital_status'],
      occupation: json['occupation'],
      citizenship: json['citizenship'],
      validUntil: json['valid_until'],
      whmcsId: json['whmcs_id'],
      npwp: json['npwp'],
      emailverified: json['emailverified'] ?? 0,
      datecreated: json['datecreated'] ?? '',
      whmcsStatus: json['whmcs_status'] ?? '',
    );
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
