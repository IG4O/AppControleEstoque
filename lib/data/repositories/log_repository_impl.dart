import '../../core/database/database_helper.dart';
import '../../domain/entities/log_entry.dart';
import '../../domain/repositories/log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  @override
  Future<List<LogEntry>> getLogs() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('logs', orderBy: 'id DESC');
    
    return maps.map((map) => LogEntry.fromMap(map)).toList();
  }

  @override
  Future<void> deleteLog(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
