import '../../core/database/database_helper.dart';
import '../../domain/entities/management.dart';
import '../../domain/repositories/management_repository.dart';

class ManagementRepositoryImpl implements ManagementRepository {
  @override
  Future<FinancialSummary> getSummary(int month, int year) async {
    final db = await DatabaseHelper.instance.database;

    // Filtro para o SQLite: formato YYYY-MM
    final monthStr = month.toString().padLeft(2, '0');
    final yearMonth = '$year-$monthStr';

    // 1. Faturamento Bruto e Custo dos Produtos Vendidos (COGS)
    // Fazemos um JOIN da tabela vendas com produtos para pegar o custo atual do produto.
    // (Em um sistema maior, o custo seria salvo na tabela de vendas no momento da venda,
    // mas para simplificar, usaremos o custo atual do produto).
    final salesResult = await db.rawQuery('''
      SELECT 
        SUM(v.totalvenda) as faturamento,
        SUM(v.quantidade * p.custo) as cogs
      FROM vendas v
      JOIN produtos p ON v.idproduto = p.id
      WHERE strftime('%Y-%m', v.data_venda) = ?
    ''', [yearMonth]);

    final faturamentoBruto = (salesResult.first['faturamento'] as num?)?.toDouble() ?? 0.0;
    final cogs = (salesResult.first['cogs'] as num?)?.toDouble() ?? 0.0;

    // 2. Despesas Adicionais (Tabela Gerenciamento)
    final expensesResult = await db.rawQuery('''
      SELECT SUM(valor) as despesas
      FROM gerenciamento
      WHERE strftime('%Y-%m', data_gasto) = ?
    ''', [yearMonth]);

    final despesas = (expensesResult.first['despesas'] as num?)?.toDouble() ?? 0.0;

    return FinancialSummary(
      faturamentoBruto: faturamentoBruto,
      custoProdutosVendidos: cogs,
      despesasAdicionais: despesas,
    );
  }

  @override
  Future<List<Expense>> getExpenses(int month, int year) async {
    final db = await DatabaseHelper.instance.database;
    
    final monthStr = month.toString().padLeft(2, '0');
    final yearMonth = '$year-$monthStr';

    final maps = await db.query(
      'gerenciamento',
      where: "strftime('%Y-%m', data_gasto) = ?",
      whereArgs: [yearMonth],
      orderBy: 'id DESC',
    );

    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  @override
  Future<List<SaleTransaction>> getSalesTransactions(int month, int year) async {
    final db = await DatabaseHelper.instance.database;
    
    final monthStr = month.toString().padLeft(2, '0');
    final yearMonth = '$year-$monthStr';

    final maps = await db.rawQuery('''
      SELECT 
        compra_id,
        MIN(data_venda) as data_venda,
        usuario,
        SUM(totalvenda) as total
      FROM vendas
      WHERE strftime('%Y-%m', data_venda) = ?
      GROUP BY compra_id
      ORDER BY data_venda DESC
    ''', [yearMonth]);

    return maps.map((map) => SaleTransaction.fromMap(map)).toList();
  }

  @override
  Future<void> addExpense(Expense expense) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('gerenciamento', expense.toMap());

    // Registra Log
    await db.insert('logs', {
      'usuario': expense.usuario,
      'acao': 'Adicionou despesa: ${expense.descricao} (R\$ ${expense.valor.toStringAsFixed(2)})',
    });
  }

  @override
  Future<void> deleteExpense(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'gerenciamento',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
