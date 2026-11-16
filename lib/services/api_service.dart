import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator testing against localhost node backend
  // For physical device, change to machine LAN IP (e.g., http://192.168.x.x:3000)
  // Or your deployed Cloudflare Worker / Cloud Run URL.
  static String baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';

  static Future<ScanResult> analyzeContract({
    String? filePath,
    String? mimeType,
    String? contractText,
    String category = 'general',
  }) async {
    final uri = Uri.parse('$baseUrl/api/scan');
    final request = http.MultipartRequest('POST', uri);

    request.fields['category'] = category;
    if (contractText != null && contractText.isNotEmpty) {
      request.fields['contract_text'] = contractText;
    }

    if (filePath != null && filePath.isNotEmpty) {
      final file = File(filePath);
      if (await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('files', filePath));
      }
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        throw Exception('Analysis request timed out. Long documents may take up to 90 seconds.');
      },
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
  }
}
