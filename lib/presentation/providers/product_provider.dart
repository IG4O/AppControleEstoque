import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/product_usecases.dart';


final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl();
});

final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  return GetProductsUseCase(ref.watch(productRepositoryProvider));
});

final addProductUseCaseProvider = Provider<AddProductUseCase>((ref) {
  return AddProductUseCase(ref.watch(productRepositoryProvider));
});

final deleteProductUseCaseProvider = Provider<DeleteProductUseCase>((ref) {
  return DeleteProductUseCase(ref.watch(productRepositoryProvider));
});

// StateNotifier para gerenciar a lista de produtos exibida na tela
final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier(
    ref.watch(getProductsUseCaseProvider),
    ref.watch(addProductUseCaseProvider),
    ref.watch(deleteProductUseCaseProvider),
  );
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final GetProductsUseCase _getProducts;
  final AddProductUseCase _addProduct;
  final DeleteProductUseCase _deleteProduct;

  ProductsNotifier(this._getProducts, this._addProduct, this._deleteProduct) : super(const AsyncLoading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncLoading();
    try {
      final products = await _getProducts();
      state = AsyncData(products);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await _addProduct(product);
      await loadProducts(); // Recarrega a lista após adicionar
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _deleteProduct(id);
      await loadProducts(); // Recarrega a lista após deletar
    } catch (e) {
      rethrow;
    }
  }
}

// Provider auxiliar para calcular o total em estoque
final totalStockValueProvider = Provider<double>((ref) {
  final productsState = ref.watch(productsProvider);
  return productsState.maybeWhen(
    data: (products) {
      return products.fold(0.0, (total, product) => total + (product.quantidade * product.valor));
    },
    orElse: () => 0.0,
  );
});
