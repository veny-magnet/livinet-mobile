import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../ticket/ticket_list_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildCustomHeader(context),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Make Ticket Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TicketListScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Make Ticket',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                CupertinoIcons.tickets,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // FAQ Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: const Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // FAQ Items
                    ..._buildFAQItems(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/help'),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CB04C), Color(0xFFF8D86E)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20), // Move content down more
              // Title and Ask LiviBot aligned horizontally
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Help',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat feature coming soon!'),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ask LiviBot',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search Answers',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontFamily: 'Open Sans',
                          fontSize: 14,
                        ),
                        suffixIcon: Icon(
                          Icons.search,
                          color: Colors.black.withOpacity(0.7),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFAQItems() {
    final faqItems = [
      {'question': 'Bagaimana cara membayar tagihan saya?', 'answer': null},
      {
        'question': 'Bagaimana cara upgrade paket internet?',
        'answer':
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
      },
      {'question': 'Bagaimana cara membayar tagihan saya?', 'answer': null},
      {'question': 'Bagaimana cara membayar tagihan saya?', 'answer': null},
      {'question': 'Bagaimana cara membayar tagihan saya?', 'answer': null},
    ];

    return faqItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final hasAnswer = item['answer'] != null;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Theme(
          data: ThemeData().copyWith(
            dividerColor: Colors.transparent,
            expansionTileTheme: const ExpansionTileThemeData(
              tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
            ),
          ),
          child: ExpansionTile(
            key: PageStorageKey<int>(index),
            title: Text(
              item['question'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontFamily: 'Open Sans',
              ),
            ),
            trailing: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.orange,
              size: 24,
            ),
            initiallyExpanded: hasAnswer,
            children: [
              if (item['answer'] != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate text height to match gradient line length
                      final textPainter = TextPainter(
                        text: TextSpan(
                          text: item['answer'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.4,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        textDirection: TextDirection.ltr,
                        maxLines: null,
                      );
                      textPainter.layout(maxWidth: constraints.maxWidth - 15);
                      final textHeight = textPainter.size.height;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3,
                            height: textHeight,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF41AD49), Color(0xFFFCBF0F)],
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(1.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['answer'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.4,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
