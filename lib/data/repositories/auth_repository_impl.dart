import '../../core/database/database_helper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User> login(String email, String password) async {
    final db = await DatabaseHelper.instance.database;

    // Faz a consulta no SQLite
    final maps = await db.query(
      'usuarios',
      columns: ['id', 'email', 'tipo'],
      where: 'email = ? AND senha = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      final userData = maps.first;
      return User(
        id: userData['id'].toString(),
        email: userData['email'] as String,
        tipo: userData['tipo'] as String? ?? 'Marcia', // fallback
      );
    } else {
      throw Exception('Email ou senha inválidos.');
    }
  }
}
