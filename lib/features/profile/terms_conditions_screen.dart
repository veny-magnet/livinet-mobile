import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
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
            'Terms and Conditions',
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
              _buildTermsSection(
                'User Agreement',
                'By registering and using this service, you agree to be bound by these terms and conditions. If you do not agree to any part of these terms, you may not use our service.',
              ),
              const SizedBox(height: 16),
              _buildTermsSection(
                'Service Usage',
                'You agree to use this service only for lawful purposes and in a way that does not infringe upon the rights of others or restrict their use and enjoyment of the service. You are responsible for maintaining the confidentiality of your account information and password.',
              ),
              const SizedBox(height: 16),
              _buildTermsSection(
                'User Responsibilities',
                'You are responsible for all activities that occur under your account. You agree to provide accurate, current, and complete information during registration. You must maintain the security of your password and immediately notify us of any unauthorized use of your account.',
              ),
              const SizedBox(height: 16),
              _buildTermsSection(
                'Content and Data',
                'You retain ownership of any content you provide. By providing content, you grant us a license to use, modify, and distribute that content. You represent and warrant that you have all rights necessary to provide such content.',
              ),
              const SizedBox(height: 16),
              _buildTermsSection(
                'Limitation of Liability',
                'To the fullest extent permitted by applicable law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to damages for loss of profits, goodwill, use, data, or other intangible losses.',
              ),
              const SizedBox(height: 16),
              _buildTermsSection(
                'Termination',
                'We reserve the right to terminate or suspend your account and access to the service at any time, without notice, for conduct that we believe violates these terms or is otherwise harmful to the service, our users, or third parties.',
              ),
              const SizedBox(height: 16),
              _buildTermsSection(
                'Changes to Terms',
                'We may modify these terms at any time. Your continued use of the service following the posting of revised terms means that you accept and agree to the changes. It is your responsibility to review these terms periodically.',
              ),
              const SizedBox(height: 16),
              _buildTermsSection(
                'Governing Law',
                'These terms and conditions are governed by and construed in accordance with the laws of Indonesia, and you irrevocably submit to the exclusive jurisdiction of the courts located therein.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Open Sans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.6,
              fontFamily: 'Open Sans',
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
