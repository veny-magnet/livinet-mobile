import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class KtpInput extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final Function(File?) onImageSelected;
  const KtpInput({ super.key, this.hintText = "Identification Card (KTP)", this.icon = Icons.credit_card_outlined, required this.onImageSelected,});
  @override
  State<KtpInput> createState() => _KtpInputState();
}

class _KtpInputState extends State<KtpInput> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, 
    );

    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      widget.onImageSelected(_imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFA5A9A9);

    return GestureDetector(
      onTap: _pickImage,
      child: AbsorbPointer(
        child: SizedBox(height: 54, width: double.infinity,
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(widget.icon, color: borderColor),
              hintText: _imageFile == null
                ? widget.hintText
                : _imageFile!.path.split('/').last,
              hintStyle: TextStyle(
                color: _imageFile == null ? borderColor : Colors.black87,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16,),
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
        ),
      ),
    );
  }
}
