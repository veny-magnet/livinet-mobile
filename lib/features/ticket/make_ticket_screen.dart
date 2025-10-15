import 'package:flutter/material.dart';
import '../../core/widgets/form_components.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/services/ticket_service.dart';
import '../../core/services/auth_service.dart';

class MakeTicketScreen extends StatefulWidget {
  const MakeTicketScreen({super.key});

  @override
  State<MakeTicketScreen> createState() => _MakeTicketScreenState();
}

class _MakeTicketScreenState extends State<MakeTicketScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TicketService _ticketService = TicketService.instance;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
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

    try {
      final userInfo = await _authService.getCurrentUser();
      final userId = userInfo?['user_id']?.toString();

      if (userId == null) {
        throw Exception('User ID not found. Please login again.');
      }

      final response = await _ticketService.openTicket(
        userId: userId,
        subject: _titleController.text,
        message: _descriptionController.text,
        date: DateTime.now().toIso8601String(),
      );

      setState(() {
        _isLoading = false;
      });

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();

        // Navigate back
        Navigator.pop(context, true); // Pass true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit ticket: ${response['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
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
