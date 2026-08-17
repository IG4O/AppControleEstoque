import 'product.dart';

class SaleItem {
  final Product product;
  final int quantidade;
  final double descontoPercentual;
  final double precoVendaEditado; // O valor base (À Vista ou Prazo)
  final bool isPrazo;
  final int parcelas;

  SaleItem({
    required this.product,
    required this.quantidade,
    required this.descontoPercentual,
    required this.precoVendaEditado,
    this.isPrazo = false,
    this.parcelas = 1,
  });

  double get precoUnidadeFinal => precoVendaEditado * (1 - (descontoPercentual / 100));
  double get subtotal => quantidade * precoUnidadeFinal;
  double get valorParcela => isPrazo ? (subtotal / parcelas) : subtotal;

  SaleItem copyWith({
    Product? product,
    int? quantidade,
    double? descontoPercentual,
    double? precoVendaEditado,
    bool? isPrazo,
    int? parcelas,
  }) {
    return SaleItem(
      product: product ?? this.product,
      quantidade: quantidade ?? this.quantidade,
      descontoPercentual: descontoPercentual ?? this.descontoPercentual,
      precoVendaEditado: precoVendaEditado ?? this.precoVendaEditado,
      isPrazo: isPrazo ?? this.isPrazo,
      parcelas: parcelas ?? this.parcelas,
    );
  }
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
