import 'package:flutter/material.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/widgets/confirmation_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  // Controllers for Profile tab
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  // Controllers for KTP tab (read-only)
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _rtController = TextEditingController();
  final TextEditingController _rwController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  final TextEditingController _maritalStatusController =
      TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _citizenshipController = TextEditingController();
  final TextEditingController _validUntilController = TextEditingController();

  String profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userIdController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _statusController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _nationalIdController.dispose();
    _fullNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthPlaceController.dispose();
    _birthDateController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _religionController.dispose();
    _maritalStatusController.dispose();
    _occupationController.dispose();
    _citizenshipController.dispose();
    _validUntilController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      const String defaultUserId = 'CR006000';
      final result = await UserProfileService.instance.getUserProfile(
        defaultUserId,
      );

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];

        setState(() {
          // Profile tab data
          _userIdController.text = data.userId ?? '';
          _usernameController.text = data.username ?? '';
          _phoneController.text = data.phone ?? '';
          _emailController.text = data.email ?? '';
          _countryController.text = data.country ?? '';
          _statusController.text = data.status == 'verified'
              ? 'Verified'
              : 'Not Verified';

          // KTP tab data
          _provinceController.text = data.province ?? '';
          _cityController.text = data.city ?? '';
          _nationalIdController.text = data.nationalIdNumber ?? '';
          _fullNameController.text = data.fullName ?? '';
          _firstNameController.text = data.firstName ?? '';
          _lastNameController.text = data.lastName ?? '';
          _birthPlaceController.text = data.birthPlace ?? '';
          _birthDateController.text = data.birthDate ?? '';
          _genderController.text = data.gender ?? '';
          _addressController.text = data.address ?? '';
          _rtController.text = data.rt ?? '';
          _rwController.text = data.rw ?? '';
          _villageController.text = data.village ?? '';
          _districtController.text = data.district ?? '';
          _religionController.text = data.religion ?? '';
          _maritalStatusController.text = data.maritalStatus ?? '';
          _occupationController.text = data.occupation ?? '';
          _citizenshipController.text = data.citizenship ?? '';
          _validUntilController.text = data.validUntil ?? '';

          profileImageUrl = data.ktp ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ],
              ),
            ),

            // Profile Photo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: profileImageUrl.isNotEmpty
                    ? Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      )
                    : const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 20),

            // Tab Bar
            Container(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicator: const BoxDecoration(color: Colors.transparent),
                    indicatorColor: Colors.transparent,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Open Sans',
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Open Sans',
                    ),
                    tabs: const [
                      Tab(text: 'Profile'),
                      Tab(text: 'KTP'),
                    ],
                  ),
                  Container(
                    height: 3,
                    margin: const EdgeInsets.only(top: 0),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CB04C), Color(0xFFF8D86E)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      indicatorColor: Colors.transparent,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.transparent,
                      unselectedLabelColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: 'Profile'),
                        Tab(text: 'KTP'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Profile Tab
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          const Text(
                            'User ID',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontFamily: 'Open Sans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            icon: Icons.badge_outlined,
                            hintText: "User ID",
                            controller: _userIdController,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'User Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontFamily: 'Open Sans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            icon: Icons.person_outline,
                            hintText: "Username",
                            controller: _usernameController,
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Phone',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontFamily: 'Open Sans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            icon: Icons.phone_outlined,
                            hintText: "Phone Number",
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontFamily: 'Open Sans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            icon: Icons.email_outlined,
                            hintText: "Email",
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Country',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontFamily: 'Open Sans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            icon: Icons.public_outlined,
                            hintText: "Country",
                            controller: _countryController,
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontFamily: 'Open Sans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            icon: Icons.verified_outlined,
                            hintText: "Status",
                            controller: _statusController,
                            enabled: false,
                          ),
                          const SizedBox(height: 32),

                          // Save Button
                          ElevatedButton(
                            onPressed: () {
                              // Show confirmation dialog before saving
                              DialogHelper.showWarning(
                                context,
                                title: 'Save Changes',
                                message:
                                    'Are you sure you want to save these changes to your profile?',
                                confirmText: 'Save',
                                cancelText: 'Cancel',
                                onConfirm: () {
                                  // Show success dialog (no API action yet)
                                  DialogHelper.showSuccess(
                                    context,
                                    title: 'Success',
                                    message: 'Profile updated successfully!',
                                    onConfirm: () {
                                      // Just dismiss for now
                                    },
                                  );
                                },
                                onCancel: () {
                                  // Do nothing, just dismiss
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CB04C),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // KTP Tab
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          _buildKTPField(
                            'Province',
                            _provinceController,
                            Icons.location_city_outlined,
                          ),
                          _buildKTPField(
                            'City',
                            _cityController,
                            Icons.location_on_outlined,
                          ),
                          _buildKTPField(
                            'National ID Number',
                            _nationalIdController,
                            Icons.credit_card_outlined,
                          ),
                          _buildKTPField(
                            'Full Name',
                            _fullNameController,
                            Icons.person_outline,
                          ),
                          _buildKTPField(
                            'First Name',
                            _firstNameController,
                            Icons.person_outline,
                          ),
                          _buildKTPField(
                            'Last Name',
                            _lastNameController,
                            Icons.person_outline,
                          ),
                          _buildKTPField(
                            'Birth Place',
                            _birthPlaceController,
                            Icons.place_outlined,
                          ),
                          _buildKTPField(
                            'Birth Date',
                            _birthDateController,
                            Icons.calendar_today_outlined,
                          ),
                          _buildKTPField(
                            'Gender',
                            _genderController,
                            Icons.wc_outlined,
                          ),
                          _buildKTPField(
                            'Address',
                            _addressController,
                            Icons.home_outlined,
                          ),
                          _buildKTPField(
                            'RT',
                            _rtController,
                            Icons.home_outlined,
                          ),
                          _buildKTPField(
                            'RW',
                            _rwController,
                            Icons.home_outlined,
                          ),
                          _buildKTPField(
                            'Village',
                            _villageController,
                            Icons.location_city_outlined,
                          ),
                          _buildKTPField(
                            'District',
                            _districtController,
                            Icons.location_city_outlined,
                          ),
                          _buildKTPField(
                            'Religion',
                            _religionController,
                            Icons.church_outlined,
                          ),
                          _buildKTPField(
                            'Marital Status',
                            _maritalStatusController,
                            Icons.favorite_outlined,
                          ),
                          _buildKTPField(
                            'Occupation',
                            _occupationController,
                            Icons.work_outline,
                          ),
                          _buildKTPField(
                            'Citizenship',
                            _citizenshipController,
                            Icons.flag_outlined,
                          ),
                          _buildKTPField(
                            'Valid Until',
                            _validUntilController,
                            Icons.schedule_outlined,
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
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

  Widget _buildKTPField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            fontFamily: 'Open Sans',
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          icon: icon,
          hintText: label,
          controller: controller,
          enabled: false,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
