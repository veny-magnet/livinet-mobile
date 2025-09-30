import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class DropdownInput<T> extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;

  const DropdownInput({super.key, required this.icon, required this.hintText, required this.items, this.value, required this.onChanged,});

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFA5A9A9);

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DropdownButtonFormField2<T>(value: value, items: items, onChanged: onChanged ,isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: borderColor),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
          borderSide:BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        ),
        hint: Text(
          hintText,
          style: const TextStyle(color: borderColor, fontSize: 14),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.keyboard_arrow_down, color: borderColor),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          width: 350,
          offset: const Offset(0, -5),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
