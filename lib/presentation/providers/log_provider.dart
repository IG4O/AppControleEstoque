import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/log_repository_impl.dart';
import '../../domain/entities/log_entry.dart';
import '../../domain/repositories/log_repository.dart';
import '../../domain/usecases/log_usecases.dart';

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepositoryImpl();
});

final getLogsUseCaseProvider = Provider<GetLogsUseCase>((ref) {
  return GetLogsUseCase(ref.watch(logRepositoryProvider));
});

final deleteLogUseCaseProvider = Provider<DeleteLogUseCase>((ref) {
  return DeleteLogUseCase(ref.watch(logRepositoryProvider));
});

final logsProvider = StateNotifierProvider<LogsNotifier, AsyncValue<List<LogEntry>>>((ref) {
  return LogsNotifier(
    ref.watch(getLogsUseCaseProvider),
    ref.watch(deleteLogUseCaseProvider),
  );
});

class LogsNotifier extends StateNotifier<AsyncValue<List<LogEntry>>> {
  final GetLogsUseCase _getLogs;
  final DeleteLogUseCase _deleteLog;

  LogsNotifier(this._getLogs, this._deleteLog) : super(const AsyncLoading()) {
    loadLogs();
  }

  Future<void> loadLogs() async {
    state = const AsyncLoading();
    try {
      final logs = await _getLogs();
      state = AsyncData(logs);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteLog(int id) async {
    try {
      await _deleteLog(id);
      await loadLogs();
    } catch (e) {
      rethrow;
    }
  }
}
