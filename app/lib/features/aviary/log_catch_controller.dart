import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/vision_service.dart';
import '../../domain/log_catch_use_case.dart';
import '../../models/parse_result.dart';
import 'aviary_providers.dart';

enum CatchFlowStatus { idle, loading, duplicate, futureDate, unverifiable }

/// [duplicateDate] is set only when status is duplicate — it's the
/// screenshot's catch day, which may not be today. [unverifiableReason]
/// is set only when status is unverifiable.
typedef CatchFlowState = ({
  CatchFlowStatus status,
  DateTime? duplicateDate,
  String? unverifiableReason,
});

const CatchFlowState _idle =
    (status: CatchFlowStatus.idle, duplicateDate: null, unverifiableReason: null);
const CatchFlowState _loading =
    (status: CatchFlowStatus.loading, duplicateDate: null, unverifiableReason: null);

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

  /// Parses the screenshot — a single-bird detail or a Merlin list. Rethrows
  /// on failure so the screen can surface the error; an unverifiable
  /// screenshot shows the rejection banner.
  Future<ParseOutcome> parseScreenshot(File file) async {
    state = _loading;
    try {
      return await ref.read(visionServiceProvider).parseScreenshot(file);
    } on UnverifiableScreenshotException catch (e) {
      state = (
        status: CatchFlowStatus.unverifiable,
        duplicateDate: null,
        unverifiableReason: e.message,
      );
      rethrow;
    } catch (_) {
      state = _idle;
      rethrow;
    }
  }

  /// Rejection check before the user is asked for anything (e.g. a manual
  /// location). Returns the rejection and shows its banner, or null when
  /// the flow may continue.
  Future<LogCatchResult?> precheck(ParseResult parse) async {
    final rejection = await ref.read(logCatchUseCaseProvider).precheck(parse);
    state = switch (rejection) {
      LogCatchDuplicate(:final date) => (
          status: CatchFlowStatus.duplicate,
          duplicateDate: date,
          unverifiableReason: null,
        ),
      LogCatchFutureDated() => (
          status: CatchFlowStatus.futureDate,
          duplicateDate: null,
          unverifiableReason: null,
        ),
      _ => _loading,
    };
    return rejection;
  }

  /// Submits the parsed catch and refreshes the aviary on success.
  Future<LogCatchResult> submit(ParseResult parse, File file) async {
    state = _loading;
    try {
      final result =
          await ref.read(logCatchUseCaseProvider)(parse: parse, screenshot: file);
      state = switch (result) {
        LogCatchDuplicate(:final date) => (
            status: CatchFlowStatus.duplicate,
            duplicateDate: date,
            unverifiableReason: null,
          ),
        LogCatchFutureDated() => (
            status: CatchFlowStatus.futureDate,
            duplicateDate: null,
            unverifiableReason: null,
          ),
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
