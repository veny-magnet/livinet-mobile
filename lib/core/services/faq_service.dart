import 'dart:convert';
import 'package:http/http.dart' as http;

class FAQService {
  static const String baseUrl = 'https://7c3591ea9167.ngrok-free.app/api/v1';

  // Cache variables
  static List<FAQ>? _cachedFAQs;
  static DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(hours: 1);

  static bool get _isCacheValid {
    return _cachedFAQs != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheExpiry;
  }

  static Future<List<FAQ>> getFAQs({bool forceRefresh = false}) async {
    print('FAQService - Getting FAQs, forceRefresh: $forceRefresh');

    if (_isCacheValid && !forceRefresh) {
      print('FAQService - Returning cached FAQs: ${_cachedFAQs!.length} items');
      return _cachedFAQs!;
    }

    try {
      print('FAQService - Making API call to: $baseUrl/get/faq');
      final response = await http.get(
        Uri.parse('$baseUrl/get/faq'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('FAQService - Response status: ${response.statusCode}');
      print('FAQService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('FAQService - Parsed JSON: $jsonResponse');

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> faqsJson = jsonResponse['data']['faqs'];
          print('FAQService - FAQs JSON: $faqsJson');
          print('FAQService - FAQs count: ${faqsJson.length}');

          final faqList = faqsJson.map((json) => FAQ.fromJson(json)).toList();
          print('FAQService - Converted FAQ objects: ${faqList.length}');

          // Update cache
          _cachedFAQs = faqList;
          _lastFetch = DateTime.now();

          return faqList;
        } else {
          print('FAQService - API response not successful or no data');
          throw Exception('Failed to load FAQs: ${jsonResponse['message']}');
        }
      } else {
        print('FAQService - HTTP error: ${response.statusCode}');
        throw Exception('Failed to load FAQs: ${response.statusCode}');
      }
    } catch (e) {
      print('FAQService - Exception caught: $e');
      if (_cachedFAQs != null) {
        print(
          'FAQService - Returning cached FAQs due to error: ${_cachedFAQs!.length} items',
        );
        return _cachedFAQs!;
      }
      throw Exception('Error fetching FAQs: $e');
    }
  }

  static void clearCache() {
    _cachedFAQs = null;
    _lastFetch = null;
  }

  static Map<String, dynamic> getCacheInfo() {
    return {
      'hasCachedData': _cachedFAQs != null,
      'lastFetch': _lastFetch?.toIso8601String(),
      'cacheValid': _isCacheValid,
      'itemCount': _cachedFAQs?.length ?? 0,
    };
  }
}

class FAQ {
  final int faqID;
  final String faqTittle;
  final String faqDesc;
  final String createdAt;
  final String updatedAt;

  FAQ({
    required this.faqID,
    required this.faqTittle,
    required this.faqDesc,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      faqID: json['faqID'] ?? 0,
      faqTittle: json['faqTittle'] ?? '',
      faqDesc: json['faqDesc'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faqID': faqID,
      'faqTittle': faqTittle,
      'faqDesc': faqDesc,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
