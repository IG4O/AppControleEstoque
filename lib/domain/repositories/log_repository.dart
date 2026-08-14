import '../entities/log_entry.dart';

abstract class LogRepository {
  Future<List<LogEntry>> getLogs();
  Future<void> deleteLog(int id);
}
