import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final IconData? icon;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;

  const TextInput({
    super.key,
    this.icon,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFA5A9A9);

    return SizedBox(
      height: maxLines != null && maxLines! > 1 ? null : 54,
      width: double.infinity,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
        style: TextStyle(color: enabled ? Colors.black87 : Colors.grey),
        decoration: InputDecoration(
          prefixIcon: icon != null
              ? Icon(icon, color: enabled ? borderColor : Colors.grey)
              : null,
          hintText: hintText,
          hintStyle: const TextStyle(color: borderColor),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
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
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
