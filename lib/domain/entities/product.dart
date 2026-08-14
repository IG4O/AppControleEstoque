class Product {
  final int? id;
  final String nome;
  final int quantidade;
  final String? usuario;
  final double valor;
  final String? dataRegistro;
  final double custo;
  final String? marca;

  Product({
    this.id,
    required this.nome,
    required this.quantidade,
    this.usuario,
    required this.valor,
    this.dataRegistro,
    required this.custo,
    this.marca,
  });

  // Factory para converter Map do SQLite em Entidade Dart
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      quantidade: map['quantidade'] as int,
      usuario: map['usuario'] as String?,
      valor: (map['valor'] as num).toDouble(),
      dataRegistro: map['dataregistro'] as String?,
      custo: (map['custo'] as num).toDouble(),
      marca: map['marca'] as String?,
    );
  }

  // Método para converter Entidade Dart em Map para o SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'quantidade': quantidade,
      'usuario': usuario,
      'valor': valor,
      'dataregistro': dataRegistro,
      'custo': custo,
      'marca': marca,
    };
  }
}
