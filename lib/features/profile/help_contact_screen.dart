import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_navigation.dart';

class HelpContactScreen extends StatefulWidget {
  const HelpContactScreen({super.key});

  @override
  State<HelpContactScreen> createState() => _HelpContactScreenState();
}

class _HelpContactScreenState extends State<HelpContactScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        titleSpacing: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Help and Contact Support',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'Open Sans',
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Need Help?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Open Sans',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: 'support@livinet.com',
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      value: '+62 xxx-xxxx-xxxx',
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      icon: Icons.language_outlined,
                      title: 'Website',
                      value: 'www.livinet.com',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Open Sans',
                ),
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                question: 'How do I reset my password?',
                answer:
                    'You can reset your password by clicking the "Forgot Password" link on the login page.',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'How can I update my profile?',
                answer:
                    'You can update your profile information from the Edit Profile section in your account settings.',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'How do I contact customer support?',
                answer:
                    'You can reach our customer support team through the contact information provided above.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/profile'),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'Open Sans',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Open Sans',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Open Sans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontFamily: 'Open Sans',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
