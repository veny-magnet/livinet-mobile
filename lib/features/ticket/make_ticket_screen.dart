import 'package:flutter/material.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/services/ticket_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/address_service.dart';
import '../../core/services/subscription_service.dart';

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
  final AddressService _addressService = AddressService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;
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

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Submitting ticket...'),
                ],
              ),
            ),
          );
        },
      );
    }

    try {
      final userInfo = await _authService.getCurrentUser();
      final userCode = userInfo?['code']
          ?.toString(); // UUID dari login response

      if (userCode == null) {
        throw Exception('User code not found. Please login again.');
      }

      // Get user's address and subscription info
      String? userAddressId;
      String? subsPlanId;

      try {
        // Get default address menggunakan userCode (UUID)
        final addressResponse = await _addressService.getUserAddresses(
          userCode,
        );
        if (addressResponse['success'] && addressResponse['data'] != null) {
          final addresses = addressResponse['data']['user_addresses'] as List?;
          if (addresses != null && addresses.isNotEmpty) {
            // Use first address as default (you can modify this logic)
            userAddressId = addresses.first['id']?.toString();
          }
        }
      } catch (e) {
        // Continue without address - it's optional
      }

      try {
        // Get active subscription menggunakan userCode (UUID)
        final subscriptionResponse = await _subscriptionService
            .getUserSubscriptions(userCode);
        if (subscriptionResponse['success'] &&
            subscriptionResponse['data'] != null) {
          final subscriptions =
              subscriptionResponse['data']['subscriptions'] as List?;
          if (subscriptions != null && subscriptions.isNotEmpty) {
            // Use first subscription as default (you can modify this logic)
            subsPlanId = subscriptions.first['subsplanID']?.toString();
          }
        }
      } catch (e) {
        // Continue without subscription - it's optional
      }

      final response = await _ticketService.openTicket(
        userId: userCode,
        subject: _titleController.text,
        message: _descriptionController.text,
        userAddressId: userAddressId,
        subsPlanId: subsPlanId,
        date: DateTime.now()
            .toIso8601String()
            .replaceFirst('T', ' ')
            .substring(0, 19),
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      setState(() {
        _isLoading = false;
      });

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear form
        _titleController.clear();
        _descriptionController.clear();

        // Navigate back
        if (mounted) {
          Navigator.pop(context, true); // Pass true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit ticket: ${response['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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

            TextInput(
              icon: Icons.filter_list_rounded,
              hintText: 'Title',
              controller: _titleController,
            ),

            const SizedBox(height: 16),

            TextInput(controller: _descriptionController, maxLines: 17),

            const SizedBox(height: 18),

            AppButton(
              text: 'Submit',
              onPressed: _isLoading ? null : _submitTicket,
              isPrimary: true,
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
