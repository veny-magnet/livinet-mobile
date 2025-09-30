import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? selectedProvince;
  String? selectedCity;
  String? selectedArea;

  void _onSignup(BuildContext context) {
    debugPrint("Signup pressed");
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFA5A9A9);
    final c = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -30, left: 0, right: 0,
          child: Image.asset(
            "assets/images/top_gradient.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: screenHeight * 0.35,
            ),
          ),
          Positioned( bottom: -30, left: 0, right: 0,
            child: Image.asset(
              "assets/images/bottom_gradient.png",
              fit: BoxFit.cover,
              width: double.infinity,
              height: screenHeight * 0.35,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "Get Started!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.green,),textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Register your address to Livinet",
                    style: TextStyle(fontSize: 14, color: c.onSurface,), textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TextInput(icon: Icons.card_giftcard, hintText: "Referral Code (Optional)",),
                          const SizedBox(height: 16),
                          const TextInput(icon: Icons.person_outline, hintText: "Username",),
                          const SizedBox(height: 16),
                          const TextInput( icon: Icons.email_outlined, hintText: "Email",),
                          const SizedBox(height: 16),
                          SizedBox(height: 54, width: double.infinity,
                            child: TextField(controller: _passwordController, obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline, color: borderColor,),
                              hintText: "Password",
                              hintStyle: const TextStyle(color: borderColor),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide:
                                  const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide:
                                  const BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: c.primary),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                  color: borderColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(height: 54, width: double.infinity,
                            child: TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline, color: borderColor,),
                                hintText: "Confirm Password",
                                hintStyle: const TextStyle(color: borderColor),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide:
                                    const BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide:
                                    const BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: c.primary),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                      ? Icons.visibility_off
                                       : Icons.visibility,
                                    color: borderColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          DropdownInput<String>(
                            icon: Icons.map_outlined,
                            hintText: "Select Province",
                            value: selectedProvince,
                            items: ["Jawa Barat", "Jawa Tengah", "Jawa Timur"]
                              .map((p) => DropdownMenuItem(value: p, child: Text(p),))
                              .toList(),
                            onChanged: (val) {
                              setState(() => selectedProvince = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          DropdownInput<String>(
                            icon: Icons.location_city_outlined,
                            hintText: "Select City",
                            value: selectedCity,
                            items: ["Bandung", "Semarang", "Surabaya"]
                              .map((c) => DropdownMenuItem(value: c, child: Text(c),))
                              .toList(),
                            onChanged: (val) {
                              setState(() => selectedCity = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          DropdownInput<String>(
                            icon: Icons.my_location_outlined,
                            hintText: "Select Area",
                            value: selectedArea,
                            items: ["Area A", "Area B", "Area C"]
                              .map((a) => DropdownMenuItem(value: a,child: Text(a),))
                              .toList(),
                            onChanged: (val) {
                              setState(() => selectedArea = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          const TextInput(icon: Icons.home_outlined, hintText: "Address",),
                          const SizedBox(height: 16),

                          const TextInput( icon: Icons.credit_card_outlined, hintText: "KTP",),
                          const SizedBox(height: 30),

                          AppButton(text: "Sign Up", onPressed: () => _onSignup(context), isPrimary: true,),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row( mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle( fontSize: 14, fontWeight: FontWeight.normal, color: c.onSurface,),
                      ),
                      GestureDetector(
                        onTap: () {
                          debugPrint("Login tapped");
                          context.go('/login');
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle( color: Colors.green, fontWeight: FontWeight.w900,),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
