import 'package:uuid/uuid.dart';

import '../entities/sale.dart';
import '../repositories/sale_repository.dart';

class RegisterSaleUseCase {
  final SaleRepository repository;
  RegisterSaleUseCase(this.repository);

  Future<void> call(List<SaleItem> items, String usuario) async {
    if (items.isEmpty) throw Exception('O carrinho está vazio.');
    
    for (var item in items) {
      if (item.quantidade <= 0) {
        throw Exception('A quantidade deve ser maior que zero.');
      }
      if (item.quantidade > item.product.quantidade) {
        throw Exception('Estoque insuficiente para o produto: ${item.product.nome}');
      }
    }

    // Gera um ID único para a compra inteira (carrinho)
    const uuid = Uuid();
    final sale = Sale(
      compraId: uuid.v4(),
      items: items,
      usuario: usuario,
    );

    await repository.registerSale(sale);
  }
}
