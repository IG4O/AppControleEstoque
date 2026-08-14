import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dona_guio.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incrementamos a versão para forçar o onUpgrade
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Como estamos em desenvolvimento, vamos recriar as tabelas para garantir a estrutura nova
      await db.execute('DROP TABLE IF EXISTS vendas');
      await db.execute('DROP TABLE IF EXISTS gerenciamento');
      await db.execute('DROP TABLE IF EXISTS logs');
      await db.execute('DROP TABLE IF EXISTS produtos');
      await db.execute('DROP TABLE IF EXISTS usuarios');
      await _createDB(db, newVersion);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabela Usuarios
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        senha TEXT NOT NULL,
        tipo TEXT DEFAULT 'Marcia'
      )
    ''');

    // Tabela Produtos
    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        quantidade INTEGER NOT NULL,
        usuario TEXT,
        valor REAL DEFAULT 0,
        dataregistro TEXT DEFAULT CURRENT_TIMESTAMP,
        custo REAL DEFAULT 0,
        marca TEXT
      )
    ''');

    // Tabela Vendas
    await db.execute('''
      CREATE TABLE vendas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        compra_id TEXT NOT NULL,
        idproduto INTEGER NOT NULL,
        quantidade INTEGER NOT NULL,
        totalvenda REAL NOT NULL,
        desconto REAL DEFAULT 0,
        usuario TEXT,
        data_venda TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (idproduto) REFERENCES produtos (id) ON DELETE CASCADE
      )
    ''');

    // Tabela Logs
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT,
        acao TEXT NOT NULL,
        data_log TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Nova Tabela: Gerenciamento (Controle de Gastos do Mês)
    await db.execute('''
      CREATE TABLE gerenciamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        data_gasto TEXT DEFAULT CURRENT_TIMESTAMP,
        usuario TEXT
      )
    ''');

    // Insere o usuário padrão de testes para permitir o login
    await db.insert('usuarios', {
      'nome': 'Administrador',
      'email': 'admin@admin.com',
      'senha': '123456', // No futuro, é bom criptografar.
      'tipo': 'Admin',
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
