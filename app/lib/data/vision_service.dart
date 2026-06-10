import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parse_result.dart';

class VisionService {
  VisionService(this._client);

  final SupabaseClient _client;

  Future<ParseResult> parseScreenshot(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';

    final response = await _client.functions.invoke(
      'parse-screenshot',
      body: {'image': base64Image, 'media_type': mediaType},
    );

    if (response.status != 200) {
      throw Exception('Failed to parse screenshot: ${response.data}');
    }

    return ParseResult.fromJson(response.data as Map<String, dynamic>);
  }
}
