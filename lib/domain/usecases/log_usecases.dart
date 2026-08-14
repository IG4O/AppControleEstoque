import '../entities/log_entry.dart';
import '../repositories/log_repository.dart';

class GetLogsUseCase {
  final LogRepository repository;
  GetLogsUseCase(this.repository);

  Future<List<LogEntry>> call() async {
    return await repository.getLogs();
  }
}

class DeleteLogUseCase {
  final LogRepository repository;
  DeleteLogUseCase(this.repository);

  Future<void> call(int id) async {
    await repository.deleteLog(id);
  }
}
