import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;

  const TextInput({
    super.key,
    required this.icon,
    required this.hintText,
    this.controller,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFA5A9A9);

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: borderColor),
          hintText: hintText,
          hintStyle: const TextStyle(color: borderColor),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
