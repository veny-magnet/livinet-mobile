import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final int maxLines;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final bool isRequired;
  final IconData? prefixIcon;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.maxLines = 1,
    this.controller,
    this.onChanged,
    this.isRequired = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Open Sans',
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
            fontFamily: 'Open Sans',
          ),
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 8,
                    top: maxLines > 1 ? 16 : 0,
                  ),
                  child: Icon(
                    prefixIcon,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: prefixIcon != null ? 4 : 20,
            vertical: maxLines > 1 ? 16 : 12,
          ),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor = Colors.green,
    this.textColor = Colors.white,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Open Sans',
                ),
              ),
      ),
    );
  }
}
