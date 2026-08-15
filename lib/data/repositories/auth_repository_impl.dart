import '../../core/database/database_helper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User> login(String identifier, String password) async {
    final db = await DatabaseHelper.instance.database;

    // Faz a consulta no SQLite (agora aceita nome ou e-mail)
    final maps = await db.query(
      'usuarios',
      columns: ['id', 'email', 'tipo'],
      where: '(email = ? OR nome = ?) AND senha = ?',
      whereArgs: [identifier, identifier, password],
    );

    if (maps.isNotEmpty) {
      final userData = maps.first;
      return User(
        id: userData['id'].toString(),
        email: userData['email'] as String,
        tipo: userData['tipo'] as String? ?? 'Marcia', // fallback
      );
    } else {
      throw Exception('Nome/E-mail ou senha inválidos.');
    }
  }
}
