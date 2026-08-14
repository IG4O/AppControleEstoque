class Expense {
  final int? id;
  final String descricao;
  final double valor;
  final String? dataGasto;
  final String? usuario;

  Expense({
    this.id,
    required this.descricao,
    required this.valor,
    this.dataGasto,
    this.usuario,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      descricao: map['descricao'] as String,
      valor: (map['valor'] as num).toDouble(),
      dataGasto: map['data_gasto'] as String?,
      usuario: map['usuario'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'data_gasto': dataGasto,
      'usuario': usuario,
    };
  }
}

class FinancialSummary {
  final double faturamentoBruto; // Soma total das vendas
  final double custoProdutosVendidos; // Soma do (custo * quantidade) dos produtos vendidos
  final double despesasAdicionais; // Soma da tabela gerenciamento (contas, etc)

  FinancialSummary({
    required this.faturamentoBruto,
    required this.custoProdutosVendidos,
    required this.despesasAdicionais,
  });

  // Lucro Real = Vendeu - Custo da Mercadoria - Despesas Fixas
  double get lucroLiquido => faturamentoBruto - custoProdutosVendidos - despesasAdicionais;
}

class SaleTransaction {
  final String compraId;
  final String dataVenda;
  final String usuario;
  final double total;

  SaleTransaction({
    required this.compraId,
    required this.dataVenda,
    required this.usuario,
    required this.total,
  });

  factory SaleTransaction.fromMap(Map<String, dynamic> map) {
    return SaleTransaction(
      compraId: map['compra_id'] as String,
      dataVenda: map['data_venda'] as String,
      usuario: map['usuario'] as String? ?? 'Desconhecido',
      total: (map['total'] as num).toDouble(),
    );
  }
}
