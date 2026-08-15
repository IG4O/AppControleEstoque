import '../../core/database/database_helper.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

class SaleRepositoryImpl implements SaleRepository {
  @override
  Future<void> registerSale(Sale sale) async {
    final db = await DatabaseHelper.instance.database;

    // Horário de São Paulo (UTC-3)
    final spTime = DateTime.now().toUtc().subtract(const Duration(hours: 3)).toIso8601String();

    // Inicia uma transação. Se der erro no meio, ele desfaz (rollback) tudo.
    await db.transaction((txn) async {
      for (var item in sale.items) {
        // 1. Registra a venda deste item (com a mesma compra_id)
        await txn.insert('vendas', {
          'compra_id': sale.compraId,
          'idproduto': item.product.id,
          'quantidade': item.quantidade,
          'totalvenda': item.subtotal,
          'desconto': item.descontoPercentual,
          'usuario': sale.usuario,
          'data_venda': spTime,
        });

        // 2. Diminui o estoque
        final novaQuantidade = item.product.quantidade - item.quantidade;
        await txn.update(
          'produtos',
          {'quantidade': novaQuantidade},
          where: 'id = ?',
          whereArgs: [item.product.id],
        );
      }

      // 3. Registra o Log da compra total
      await txn.insert('logs', {
        'usuario': sale.usuario,
        'acao': 'Registrou uma venda de R\$ ${sale.total.toStringAsFixed(2)}',
        'data_log': spTime,
      });
    });
  }
}
