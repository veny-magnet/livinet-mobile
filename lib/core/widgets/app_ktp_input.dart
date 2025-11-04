import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class KtpInput extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final Function(File?) onImageSelected;
  const KtpInput({
    super.key,
    this.hintText = "Identification Card (KTP)",
    this.icon = Icons.credit_card_outlined,
    required this.onImageSelected,
  });
  @override
  State<KtpInput> createState() => _KtpInputState();
}

class _KtpInputState extends State<KtpInput> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      widget.onImageSelected(_imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: _imageFile != null
                    ? Colors.green
                    : const Color(0xFFA5A9A9),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _imageFile != null
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _imageFile != null ? Icons.check_circle : Icons.upload_file,
                    color: _imageFile != null
                        ? Colors.green
                        : const Color(0xFFA5A9A9),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _imageFile != null
                            ? 'KTP Uploaded'
                            : 'Upload National Identity Card',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _imageFile != null
                              ? Colors.green
                              : const Color(0xFFA5A9A9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _imageFile != null
                            ? _imageFile!.path.split('/').last
                            : 'Tap to select KTP image',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA5A9A9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  _imageFile != null ? Icons.edit : Icons.arrow_forward_ios,
                  color: const Color(0xFFA5A9A9),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
