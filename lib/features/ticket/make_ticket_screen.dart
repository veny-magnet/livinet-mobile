import 'package:flutter/material.dart';
import '../../core/widgets/form_components.dart';
import '../../core/widgets/app_bottom_navigation.dart';

class MakeTicketScreen extends StatefulWidget {
  const MakeTicketScreen({super.key});

  @override
  State<MakeTicketScreen> createState() => _MakeTicketScreenState();
}

class _MakeTicketScreenState extends State<MakeTicketScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Make Ticket',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Open Sans',
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            CustomTextField(
              hintText: 'Title',
              controller: _titleController,
              isRequired: true,
              prefixIcon: Icons.filter_list_rounded,
            ),

            CustomTextField(
              hintText: 'Description',
              controller: _descriptionController,
              isRequired: true,
              maxLines: 17,
            ),

            const SizedBox(height: 18),

            CustomButton(
              text: 'Submit',
              onPressed: _submitTicket,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 32),

            // Extra space for keyboard
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/help'),
    );
  }
}
