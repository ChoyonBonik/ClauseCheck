import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/scan_result.dart';

class ApiService {
  // 127.0.0.1 works over USB cable with `adb reverse tcp:3000 tcp:3000`
  // 192.168.0.117 is the host PC's Wi-Fi LAN IP fallback
  static const List<String> candidateUrls = [
    'http://127.0.0.1:3000',
    'http://10.0.2.2:3000',
    'http://192.168.0.117:3000',
  ];

  static Future<ScanResult> analyzeContract({
    String? filePath,
    String? mimeType,
    String? contractText,
    String category = 'general',
  }) async {
    Exception? lastError;

    for (final base in candidateUrls) {
      try {
        final uri = Uri.parse('$base/api/scan');
        final request = http.MultipartRequest('POST', uri);

        request.fields['category'] = category;
        if (contractText != null && contractText.isNotEmpty) {
          request.fields['contract_text'] = contractText;
        }

        if (filePath != null && filePath.isNotEmpty) {
          final file = File(filePath);
          if (await file.exists()) {
            final ext = filePath.split('.').last.toLowerCase();
            MediaType mediaType;
            if (ext == 'jpg' || ext == 'jpeg') {
              mediaType = MediaType('image', 'jpeg');
            } else if (ext == 'png') {
              mediaType = MediaType('image', 'png');
            } else if (ext == 'webp') {
              mediaType = MediaType('image', 'webp');
            } else {
              mediaType = MediaType('application', 'pdf');
            }

            request.files.add(await http.MultipartFile.fromPath(
              'files',
              filePath,
              contentType: mediaType,
            ));
          }
        }

        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 40),
          onTimeout: () => throw Exception('Request to $base timed out.'),
        );

        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['analysis'] != null) {
            return ScanResult.fromJson(data['analysis']);
          } else {
            throw Exception(data['error'] ?? 'Failed to parse AI response');
          }
        } else {
          final data = json.decode(response.body);
          throw Exception(data['error'] ?? 'Server error: ${response.statusCode}');
        }
      } catch (e) {
        lastError = Exception('Failed on $base: ${e.toString()}');
        continue; // Try next candidate URL
      }
    }

    throw lastError ?? Exception('Could not connect to backend server. Make sure node server.js is running.');
  }
}
