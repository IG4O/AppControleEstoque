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
      version: 5, // Incrementamos a versão para adicionar is_prazo, parcelas e valor_unitario
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
    if (oldVersion < 3) {
      // Otimização: Criando índices para acelerar consultas nas telas de Gerenciamento
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vendas_data ON vendas (data_venda)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vendas_compra_id ON vendas (compra_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_gerenciamento_data ON gerenciamento (data_gasto)');
    }
    if (oldVersion < 4) {
      // Nova funcionalidade: Preço a prazo
      await db.execute('ALTER TABLE produtos ADD COLUMN valor_prazo REAL DEFAULT 0');
    }
    if (oldVersion < 5) {
      // Campos adicionais para registrar detalhes da venda
      await db.execute('ALTER TABLE vendas ADD COLUMN is_prazo INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE vendas ADD COLUMN parcelas INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE vendas ADD COLUMN valor_unitario REAL DEFAULT 0');
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
        marca TEXT,
        valor_prazo REAL DEFAULT 0
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
        is_prazo INTEGER DEFAULT 0,
        parcelas INTEGER DEFAULT 1,
        valor_unitario REAL DEFAULT 0,
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

    // Otimização: Cria os índices iniciais
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vendas_data ON vendas (data_venda)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vendas_compra_id ON vendas (compra_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_gerenciamento_data ON gerenciamento (data_gasto)');
  }

  Future<void> logGlobalError(String errorMsg) async {
    try {
      final db = await instance.database;
      final spTime = DateTime.now().toUtc().subtract(const Duration(hours: 3)).toIso8601String();
      await db.insert('logs', {
        'usuario': 'SISTEMA',
        'acao': '[ERRO] $errorMsg',
        'data_log': spTime,
      });
    } catch (_) {
      // Se falhar até para salvar o erro, apenas ignora para não causar loop
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
