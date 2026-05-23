import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aviary_card.dart';
import '../models/catch_result.dart';

class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<List<AviaryCard>> fetchAviary() async {
    final rows = await _db
        .from('aviary_cards')
        .select()
        .eq('user_id', _userId)
        .order('species_name');
    return rows.map(AviaryCard.fromJson).toList();
  }

  /// Uploads [imageBytes] to Supabase Storage and returns the public URL.
  Future<String> uploadScreenshot(Uint8List imageBytes) async {
    final path = '$_userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _db.storage.from('screenshots').uploadBinary(path, imageBytes);
    return _db.storage.from('screenshots').getPublicUrl(path);
  }

  /// Calls the parse-screenshot Edge Function and applies the result to the DB.
  Future<CatchResult> processScreenshot(Uint8List imageBytes) async {
    final screenshotUrl = await uploadScreenshot(imageBytes);

    final response = await _db.functions.invoke(
      'parse-screenshot',
      body: {'screenshot_url': screenshotUrl},
    );

    if (response.status != 200) {
      return ParseFailure('Edge Function returned ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    final parsed = _ParsedBird.fromJson(data);

    if (!parsed.confident) {
      return ParseFailure(parsed.reason ?? 'Could not identify a Merlin screenshot.');
    }

    return _applyParsedBird(parsed, screenshotUrl);
  }

  Future<CatchResult> _applyParsedBird(
    _ParsedBird parsed,
    String screenshotUrl,
  ) async {
    final today = DateTime.now().toLocal();
    final todayDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Check daily limit — the DB unique index enforces this too; we check here
    // for a user-friendly error before hitting a DB constraint.
    final existing = await _db
        .from('catch_log')
        .select('id')
        .eq('user_id', _userId)
        .eq('species_name', parsed.speciesName)
        .eq('caught_at', todayDate)
        .maybeSingle();

    if (existing != null) {
      return DailyLimitReached(parsed.speciesName);
    }

    // Is this a new lifer?
    final existingCard = await _db
        .from('aviary_cards')
        .select()
        .eq('user_id', _userId)
        .eq('species_name', parsed.speciesName)
        .maybeSingle();

    if (existingCard == null) {
      return _createNewLifer(parsed, screenshotUrl, todayDate);
    } else {
      return _awardXp(AviaryCard.fromJson(existingCard), parsed, screenshotUrl, todayDate);
    }
  }

  Future<NewLifer> _createNewLifer(
    _ParsedBird parsed,
    String screenshotUrl,
    String todayDate,
  ) async {
    final row = await _db
        .from('aviary_cards')
        .insert({
          'user_id': _userId,
          'species_name': parsed.speciesName,
          'rarity': parsed.rarity,
          'level': 1,
          'xp': 0,
          'first_catch_date': todayDate,
          'first_catch_location': parsed.location,
          'screenshot_url': screenshotUrl,
        })
        .select()
        .single();

    await _logCatch(parsed.speciesName, todayDate, screenshotUrl, 0);
    return NewLifer(AviaryCard.fromJson(row));
  }

  Future<XpAwarded> _awardXp(
    AviaryCard card,
    _ParsedBird parsed,
    String screenshotUrl,
    String todayDate,
  ) async {
    final xpGain = card.rarity.xpPerCatch;
    final newXp = card.xp + xpGain;
    final newLevel = _calculateLevel(newXp);
    final didLevelUp = newLevel > card.level;

    final row = await _db
        .from('aviary_cards')
        .update({'xp': newXp, 'level': newLevel})
        .eq('id', card.id)
        .select()
        .single();

    await _logCatch(parsed.speciesName, todayDate, screenshotUrl, xpGain);
    return XpAwarded(
      card: AviaryCard.fromJson(row),
      xpGained: xpGain,
      didLevelUp: didLevelUp,
    );
  }

  Future<void> _logCatch(
    String speciesName,
    String date,
    String screenshotUrl,
    int xpAwarded,
  ) async {
    await _db.from('catch_log').insert({
      'user_id': _userId,
      'species_name': speciesName,
      'caught_at': date,
      'screenshot_url': screenshotUrl,
      'xp_awarded': xpAwarded,
    });
  }

  /// XP-to-level formula: level N requires N*(N-1)/2 * 20 cumulative XP.
  int _calculateLevel(int totalXp) {
    var level = 1;
    var threshold = 0;
    while (true) {
      threshold += level * 20;
      if (totalXp < threshold) break;
      level++;
    }
    return level;
  }
}

class _ParsedBird {
  const _ParsedBird({
    required this.confident,
    required this.speciesName,
    required this.rarity,
    this.location,
    this.reason,
  });

  factory _ParsedBird.fromJson(Map<String, dynamic> json) => _ParsedBird(
        confident: json['confident'] as bool? ?? false,
        speciesName: json['species_name'] as String? ?? '',
        rarity: json['rarity'] as String? ?? 'common',
        location: json['location'] as String?,
        reason: json['reason'] as String?,
      );

  final bool confident;
  final String speciesName;
  final String rarity;
  final String? location;
  final String? reason;
}
