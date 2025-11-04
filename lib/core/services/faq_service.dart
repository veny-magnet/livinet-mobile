import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'app_logger.dart';

class FAQService {
  static final _config = AppConfig.instance;
  static String get baseUrl => _config.baseUrl;
  static final _logger = AppLogger.instance;

  static Future<List<FAQ>> getFAQs({bool forceRefresh = false}) async {
    _logger.debug('FAQService - Getting FAQs, forceRefresh: $forceRefresh');

    try {
      _logger.debug('FAQService - Making API call to: $baseUrl/get/faq');
      final response = await http.get(
        Uri.parse('$baseUrl/get/faq'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      _logger.debug('Response status: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        _logger.debug('Parsed JSON: $jsonResponse');

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> faqsJson = jsonResponse['data']['faqs'];
          _logger.debug('FAQs JSON: $faqsJson');
          _logger.debug('FAQs count: ${faqsJson.length}');

          final faqList = faqsJson.map((json) => FAQ.fromJson(json)).toList();
          _logger.debug('Converted FAQ objects: ${faqList.length}');

          return faqList;
        } else {
          _logger.warning('API response not successful or no data');
          throw Exception('Failed to load FAQs: ${jsonResponse['message']}');
        }
      } else {
        _logger.warning('HTTP error: ${response.statusCode}');
        throw Exception('Failed to load FAQs: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Exception caught', e);
      rethrow;
    }
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
