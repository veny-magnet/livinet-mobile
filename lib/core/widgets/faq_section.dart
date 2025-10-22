import 'package:flutter/material.dart';
import '../services/faq_service.dart';

class FAQSection extends StatefulWidget {
  const FAQSection({super.key});

  @override
  State<FAQSection> createState() => _FAQSectionState();
}

class _FAQSectionState extends State<FAQSection> {
  List<FAQ> faqs = [];
  bool isLoading = true;
  String? errorMessage;
  Set<int> expandedItems = {};

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs({bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    } else {
      // Check cache asynchronously
      final cacheInfo = await FAQService.getCacheInfo();
      if (cacheInfo['hasCachedData'] == false) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }
    }

    try {
      final faqList = await FAQService.getFAQs(forceRefresh: forceRefresh);
      setState(() {
        faqs = faqList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        faqs = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && faqs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Failed to load FAQs',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontFamily: 'Open Sans',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _loadFAQs(forceRefresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: faqs.asMap().entries.map((entry) {
        final index = entry.key;
        final faq = entry.value;
        final hasAnswer = faq.faqDesc.isNotEmpty;

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
                faq.faqTittle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontFamily: 'Open Sans',
                ),
              ),
              trailing: AnimatedRotation(
                turns: expandedItems.contains(index) ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              initiallyExpanded: false,
              onExpansionChanged: (expanded) {
                setState(() {
                  if (expanded) {
                    expandedItems.add(index);
                  } else {
                    expandedItems.remove(index);
                  }
                });
              },
              children: [
                if (hasAnswer)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate text height to match gradient line length
                        final textPainter = TextPainter(
                          text: TextSpan(
                            text: faq.faqDesc,
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
                                  colors: [
                                    Color(0xFF41AD49),
                                    Color(0xFFFCBF0F),
                                  ],
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(1.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                faq.faqDesc,
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
      }).toList(),
    );
  }
}
