import '../../core/database/database_helper.dart';
import '../../domain/entities/management.dart';
import '../../domain/repositories/management_repository.dart';

class ManagementRepositoryImpl implements ManagementRepository {
  @override
  Future<FinancialSummary> getSummary(int month, int year) async {
    final db = await DatabaseHelper.instance.database;

    final monthStr = month.toString().padLeft(2, '0');
    final startRange = '$year-$monthStr-01';
    
    // Calculates the start of the next month to do `date < next_month`
    final nextMonthDate = DateTime(year, month + 1, 1);
    final nextMonthStr = nextMonthDate.month.toString().padLeft(2, '0');
    final nextYearStr = nextMonthDate.year.toString();
    final endRange = '$nextYearStr-$nextMonthStr-01';

    final salesResult = await db.rawQuery('''
      SELECT 
        SUM(v.totalvenda) as faturamento,
        SUM(v.quantidade * p.custo) as cogs
      FROM vendas v
      JOIN produtos p ON v.idproduto = p.id
      WHERE v.data_venda >= ? AND v.data_venda < ?
    ''', [startRange, endRange]);

    final faturamentoBruto = (salesResult.first['faturamento'] as num?)?.toDouble() ?? 0.0;
    final cogs = (salesResult.first['cogs'] as num?)?.toDouble() ?? 0.0;

    final expensesResult = await db.rawQuery('''
      SELECT SUM(valor) as despesas
      FROM gerenciamento
      WHERE data_gasto >= ? AND data_gasto < ?
    ''', [startRange, endRange]);

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
    final startRange = '$year-$monthStr-01';
    
    final nextMonthDate = DateTime(year, month + 1, 1);
    final nextMonthStr = nextMonthDate.month.toString().padLeft(2, '0');
    final nextYearStr = nextMonthDate.year.toString();
    final endRange = '$nextYearStr-$nextMonthStr-01';

    final maps = await db.query(
      'gerenciamento',
      where: "data_gasto >= ? AND data_gasto < ?",
      whereArgs: [startRange, endRange],
      orderBy: 'id DESC',
    );

    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  @override
  Future<List<SaleTransaction>> getSalesTransactions(int month, int year) async {
    final db = await DatabaseHelper.instance.database;
    
    final monthStr = month.toString().padLeft(2, '0');
    final startRange = '$year-$monthStr-01';
    
    final nextMonthDate = DateTime(year, month + 1, 1);
    final nextMonthStr = nextMonthDate.month.toString().padLeft(2, '0');
    final nextYearStr = nextMonthDate.year.toString();
    final endRange = '$nextYearStr-$nextMonthStr-01';

    final maps = await db.rawQuery('''
      SELECT 
        compra_id,
        MIN(data_venda) as data_venda,
        usuario,
        SUM(totalvenda) as total
      FROM vendas
      WHERE data_venda >= ? AND data_venda < ?
      GROUP BY compra_id
      ORDER BY data_venda DESC
    ''', [startRange, endRange]);

    return maps.map((map) => SaleTransaction.fromMap(map)).toList();
  }

  @override
  Future<List<SaleItemDetail>> getSaleDetails(String compraId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.rawQuery('''
      SELECT 
        p.nome as produto_nome,
        v.quantidade,
        v.totalvenda,
        v.desconto
      FROM vendas v
      INNER JOIN produtos p ON v.idproduto = p.id
      WHERE v.compra_id = ?
    ''', [compraId]);

    return maps.map((map) => SaleItemDetail.fromMap(map)).toList();
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
