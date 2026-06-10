import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/log_catch_use_case.dart';
import '../../models/parse_result.dart';
import 'aviary_providers.dart';

enum CatchFlowStatus { idle, loading, duplicate, futureDate }

final logCatchControllerProvider =
    NotifierProvider<LogCatchController, CatchFlowStatus>(
  LogCatchController.new,
);

/// Drives the log-a-catch flow. The screen handles picking, dialogs, and
/// navigation; this controller owns the flow state and delegates the rules
/// to LogCatchUseCase.
class LogCatchController extends Notifier<CatchFlowStatus> {
  @override
  CatchFlowStatus build() => CatchFlowStatus.idle;

  void dismissBanner() => state = CatchFlowStatus.idle;

  /// Parses the screenshot. Rethrows on failure so the screen can surface
  /// the error; state is reset either way.
  Future<ParseResult> parseScreenshot(File file) async {
    state = CatchFlowStatus.loading;
    try {
      return await ref.read(visionServiceProvider).parseScreenshot(file);
    } catch (_) {
      state = CatchFlowStatus.idle;
      rethrow;
    }
  }

  /// Submits the parsed catch and refreshes the aviary on success.
  Future<LogCatchResult> submit(ParseResult parse, File file) async {
    state = CatchFlowStatus.loading;
    try {
      final result =
          await ref.read(logCatchUseCaseProvider)(parse: parse, screenshot: file);
      state = switch (result) {
        LogCatchDuplicate() => CatchFlowStatus.duplicate,
        LogCatchFutureDated() => CatchFlowStatus.futureDate,
        _ => CatchFlowStatus.idle,
      };
      if (result is LogCatchNewLifer || result is LogCatchXpAwarded) {
        ref.invalidate(aviaryProvider);
      }
      return result;
    } catch (_) {
      state = CatchFlowStatus.idle;
      rethrow;
    }
  }
}
