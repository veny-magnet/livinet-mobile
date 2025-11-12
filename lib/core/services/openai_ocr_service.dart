import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIOcrService {
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<Map<String, dynamic>?> extractKtpData(File ktpImage) async {
    try {
      debugPrint('[OpenAI OCR] Starting KTP extraction...');

      if (_apiKey.isEmpty) {
        throw Exception('OPENAI_API_KEY not configured');
      }

      // Read image file
      final imageBytes = await ktpImage.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      const String extractionPrompt =
          '''Anda adalah expert dalam membaca KTP Indonesia. 
Ekstrak data KTP dari gambar ini dan return hasil dalam format JSON PURE (tanpa markdown).

Return format HARUS valid JSON dengan fields berikut:
{
  "nik": "string 16 digit",
  "nama": "string nama lengkap",
  "tempat_lahir": "string tempat lahir",
  "tanggal_lahir": "format DD-MM-YYYY",
  "jenis_kelamin": "LAKI-LAKI atau PEREMPUAN",
  "alamat": "string alamat lengkap",
  "rt": "string 3 digit",
  "rw": "string 3 digit",
  "kelurahan": "string kelurahan/desa",
  "kecamatan": "string kecamatan",
  "agama": "ISLAM, KRISTEN, KATOLIK, HINDU, BUDDHA, atau KHONGHUCU",
  "status_perkawinan": "BELUM KAWIN, KAWIN, CERAI HIDUP, atau CERAI MATI",
  "pekerjaan": "string pekerjaan",
  "kewarganegaraan": "WNI atau WNA",
  "berlaku_hingga": "string tanggal atau SEUMUR HIDUP",
  "provinsi": "string provinsi",
  "kota": "string kota/kabupaten"
}

RULES:
1. Ekstrak SEMUA data yang terlihat di KTP
2. Jika ada typo OCR (contoh: 1SLAM → ISLAM), koreksikan
3. Pisahkan TEMPAT LAHIR dan TANGGAL LAHIR jika ada koma
4. Format RT dan RW tanpa slash, hanya digit
5. Jika field kosong atau tidak terlihat, gunakan empty string ""
6. HANYA return JSON, tidak ada teks lain''';

      debugPrint('[OpenAI OCR] Sending request to GPT-4 Vision...');

      // Prepare request body
      final requestBody = {
        'model': 'gpt-5',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
              {'type': 'text', 'text': extractionPrompt},
            ],
          },
        ],
      };

      // Make API request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('[OpenAI OCR] Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        debugPrint('[OpenAI OCR] API Error: $error');
        throw Exception(
          'OpenAI API Error: ${error['error']?['message'] ?? 'Unknown error'}',
        );
      }

      // Parse response
      final responseData = jsonDecode(response.body);
      final responseText =
          responseData['choices']?[0]?['message']?['content'] ?? '';

      if (responseText.isEmpty) {
        throw Exception('Empty response from OpenAI');
      }

      debugPrint('[OpenAI OCR] Raw response:\n$responseText');

      // Extract JSON from response
      final jsonString = _extractJsonFromResponse(responseText);
      final Map<String, dynamic> ktpData = jsonDecode(jsonString);

      debugPrint('[OpenAI OCR] Successfully extracted KTP data');
      _logExtractedData(ktpData);

      return ktpData;
    } catch (e) {
      debugPrint('[OpenAI OCR] Error: $e');
      rethrow;
    }
  }

  /// Extract JSON dari response (handle markdown code blocks)
  static String _extractJsonFromResponse(String response) {
    // Remove markdown code blocks jika ada
    String json = response;

    // Remove ```json ... ``` blocks
    if (json.contains('```json')) {
      final start = json.indexOf('```json') + 7;
      final end = json.lastIndexOf('```');
      json = json.substring(start, end);
    } else if (json.contains('```')) {
      final start = json.indexOf('```') + 3;
      final end = json.lastIndexOf('```');
      json = json.substring(start, end);
    }

    return json.trim();
  }

  /// Log extracted data untuk debugging
  static void _logExtractedData(Map<String, dynamic> data) {
    debugPrint('[OpenAI OCR] === Extracted KTP Data ===');
    debugPrint('[OpenAI OCR] NIK: ${data['nik']}');
    debugPrint('[OpenAI OCR] Nama: ${data['nama']}');
    debugPrint('[OpenAI OCR] Tempat Lahir: ${data['tempat_lahir']}');
    debugPrint('[OpenAI OCR] Tanggal Lahir: ${data['tanggal_lahir']}');
    debugPrint('[OpenAI OCR] Jenis Kelamin: ${data['jenis_kelamin']}');
    debugPrint('[OpenAI OCR] Alamat: ${data['alamat']}');
    debugPrint('[OpenAI OCR] RT/RW: ${data['rt']}/${data['rw']}');
    debugPrint('[OpenAI OCR] Kelurahan: ${data['kelurahan']}');
    debugPrint('[OpenAI OCR] Kecamatan: ${data['kecamatan']}');
    debugPrint('[OpenAI OCR] Agama: ${data['agama']}');
    debugPrint('[OpenAI OCR] Status Perkawinan: ${data['status_perkawinan']}');
    debugPrint('[OpenAI OCR] Pekerjaan: ${data['pekerjaan']}');
    debugPrint('[OpenAI OCR] Kewarganegaraan: ${data['kewarganegaraan']}');
    debugPrint('[OpenAI OCR] Berlaku Hingga: ${data['berlaku_hingga']}');
    debugPrint('[OpenAI OCR] Provinsi: ${data['provinsi']}');
    debugPrint('[OpenAI OCR] Kota: ${data['kota']}');
    debugPrint('[OpenAI OCR] ============================');
  }

  /// Returns true if data appears to be valid KTP data
  static bool validateKtpData(Map<String, dynamic> data) {
    // Check if essential KTP fields are present and non-empty
    final nik = data['nik']?.toString().trim() ?? '';
    final nama = data['nama']?.toString().trim() ?? '';
    final tempat_lahir = data['tempat_lahir']?.toString().trim() ?? '';
    final tanggal_lahir = data['tanggal_lahir']?.toString().trim() ?? '';
    final jenis_kelamin = data['jenis_kelamin']?.toString().trim() ?? '';

    // NIK should be 16 digits
    if (!RegExp(r'^\d{16}$').hasMatch(nik)) {
      debugPrint('[OpenAI OCR] Validation failed: Invalid NIK format');
      return false;
    }

    // Name should have at least 2 characters
    if (nama.length < 2) {
      debugPrint('[OpenAI OCR] Validation failed: Name too short');
      return false;
    }

    // Birth place should not be empty
    if (tempat_lahir.isEmpty) {
      debugPrint('[OpenAI OCR] Validation failed: Birth place empty');
      return false;
    }

    // Birth date should match DD-MM-YYYY format
    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(tanggal_lahir)) {
      debugPrint('[OpenAI OCR] Validation failed: Invalid birth date format');
      return false;
    }

    // Gender should be LAKI-LAKI or PEREMPUAN
    if (jenis_kelamin != 'LAKI-LAKI' && jenis_kelamin != 'PEREMPUAN') {
      debugPrint('[OpenAI OCR] Validation failed: Invalid gender');
      return false;
    }

    debugPrint('[OpenAI OCR] Data validation passed');
    return true;
  }
}
