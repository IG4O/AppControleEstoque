import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository repository;
  GetProductsUseCase(this.repository);

  Future<List<Product>> call() async {
    return await repository.getProducts();
  }
}

class AddProductUseCase {
  final ProductRepository repository;
  AddProductUseCase(this.repository);

  Future<void> call(Product product) async {
    if (product.nome.isEmpty) throw Exception('O nome do produto é obrigatório.');
    if (product.quantidade < 0) throw Exception('A quantidade não pode ser negativa.');
    if (product.valor < 0 || product.custo < 0) throw Exception('Valores não podem ser negativos.');

    await repository.addProduct(product);
  }
}

class UpdateProductUseCase {
  final ProductRepository repository;
  UpdateProductUseCase(this.repository);

  Future<void> call(Product product) async {
    await repository.updateProduct(product);
  }
}

class DeleteProductUseCase {
  final ProductRepository repository;
  DeleteProductUseCase(this.repository);

  Future<void> call(int id) async {
    await repository.deleteProduct(id);
  }
}
