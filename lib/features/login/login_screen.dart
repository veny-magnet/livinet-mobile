import 'package:flutter/material.dart';
import '../../core/widgets/app_text_input.dart'; 

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              TextInput(
                icon: Icons.email_outlined,
                hintText: "Email",
              ),
              SizedBox(height: 16),
              TextInput(
                icon: Icons.lock_outline,
                hintText: "Password",
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
