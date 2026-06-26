import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bulk_parse.dart';
import '../models/parse_result.dart';

/// The screenshot couldn't be verified — e.g. the bird's name or the date
/// isn't legible — so no catch may be logged from it.
class UnverifiableScreenshotException implements Exception {
  UnverifiableScreenshotException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The parser auto-detects whether a screenshot is a single-bird detail or a
/// Merlin "Identify" list, and the flow branches on which.
sealed class ParseOutcome {
  const ParseOutcome();
}

class ParsedSingle extends ParseOutcome {
  const ParsedSingle(this.result);
  final ParseResult result;
}

class ParsedList extends ParseOutcome {
  const ParsedList(this.bulk);
  final BulkParse bulk;
}

class VisionService {
  VisionService(this._client);

  final SupabaseClient _client;

  Future<ParseOutcome> parseScreenshot(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';

    try {
      final response = await _client.functions.invoke(
        'parse-screenshot',
        body: {'image': base64Image, 'media_type': mediaType},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      return data['type'] == 'list'
          ? ParsedList(BulkParse.fromJson(data))
          : ParsedSingle(ParseResult.fromJson(data));
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
