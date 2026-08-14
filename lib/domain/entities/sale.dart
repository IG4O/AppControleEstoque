import 'product.dart';

class SaleItem {
  final Product product;
  final int quantidade;
  final double descontoPercentual;
  final double precoVendaEditado; // Pode ter sido alterado no PDV

  SaleItem({
    required this.product,
    required this.quantidade,
    required this.descontoPercentual,
    required this.precoVendaEditado,
  });

  double get subtotal => quantidade * precoVendaEditado * (1 - (descontoPercentual / 100));
}

class Sale {
  final String compraId;
  final List<SaleItem> items;
  final String usuario;
  final String? dataVenda;

  Sale({
    required this.compraId,
    required this.items,
    required this.usuario,
    this.dataVenda,
  });

  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);
}
