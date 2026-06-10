import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parse_result.dart';

/// The screenshot couldn't be verified — e.g. the bird's name or the date
/// isn't legible — so no catch may be logged from it.
class UnverifiableScreenshotException implements Exception {
  UnverifiableScreenshotException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VisionService {
  VisionService(this._client);

  final SupabaseClient _client;

  Future<ParseResult> parseScreenshot(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';

    try {
      final response = await _client.functions.invoke(
        'parse-screenshot',
        body: {'image': base64Image, 'media_type': mediaType},
      );
      return ParseResult.fromJson(response.data as Map<String, dynamic>);
    } on FunctionException catch (e) {
      final details = e.details;
      if (e.status == 422 &&
          details is Map &&
          details['error'] == 'unverifiable') {
        throw UnverifiableScreenshotException(
          details['message'] as String? ??
              "Couldn't verify this catch from the screenshot.",
        );
      }
      throw Exception('Failed to parse screenshot: ${e.details ?? e.reasonPhrase}');
    }
  }
}
