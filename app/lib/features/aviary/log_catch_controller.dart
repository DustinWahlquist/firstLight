import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/log_catch_use_case.dart';
import '../../models/parse_result.dart';
import 'aviary_providers.dart';

enum CatchFlowStatus { idle, loading, duplicate, futureDate }

/// [duplicateDate] is set only when status is duplicate — it's the
/// screenshot's catch day, which may not be today.
typedef CatchFlowState = ({CatchFlowStatus status, DateTime? duplicateDate});

const CatchFlowState _idle = (status: CatchFlowStatus.idle, duplicateDate: null);
const CatchFlowState _loading = (status: CatchFlowStatus.loading, duplicateDate: null);

final logCatchControllerProvider =
    NotifierProvider<LogCatchController, CatchFlowState>(
  LogCatchController.new,
);

/// Drives the log-a-catch flow. The screen handles picking, dialogs, and
/// navigation; this controller owns the flow state and delegates the rules
/// to LogCatchUseCase.
class LogCatchController extends Notifier<CatchFlowState> {
  @override
  CatchFlowState build() => _idle;

  void dismissBanner() => state = _idle;

  /// Parses the screenshot. Rethrows on failure so the screen can surface
  /// the error; state is reset either way.
  Future<ParseResult> parseScreenshot(File file) async {
    state = _loading;
    try {
      return await ref.read(visionServiceProvider).parseScreenshot(file);
    } catch (_) {
      state = _idle;
      rethrow;
    }
  }

  /// Submits the parsed catch and refreshes the aviary on success.
  Future<LogCatchResult> submit(ParseResult parse, File file) async {
    state = _loading;
    try {
      final result =
          await ref.read(logCatchUseCaseProvider)(parse: parse, screenshot: file);
      state = switch (result) {
        LogCatchDuplicate(:final date) =>
          (status: CatchFlowStatus.duplicate, duplicateDate: date),
        LogCatchFutureDated() =>
          (status: CatchFlowStatus.futureDate, duplicateDate: null),
        _ => _idle,
      };
      if (result is LogCatchNewLifer || result is LogCatchXpAwarded) {
        ref.invalidate(aviaryProvider);
      }
      return result;
    } catch (_) {
      state = _idle;
      rethrow;
    }
  }
}
