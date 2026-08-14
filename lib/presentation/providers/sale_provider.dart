import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/sale_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/usecases/register_sale_usecase.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepositoryImpl();
});

final registerSaleUseCaseProvider = Provider<RegisterSaleUseCase>((ref) {
  return RegisterSaleUseCase(ref.watch(saleRepositoryProvider));
});

// Gerencia a lista de itens no carrinho de compras
class CartNotifier extends StateNotifier<List<SaleItem>> {
  CartNotifier() : super([]);

  void addProduct(Product product) {
    // Verifica se já está no carrinho
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      // Se já está, aumenta a quantidade se houver estoque
      final item = state[existingIndex];
      if (item.quantidade < product.quantidade) {
        updateItemQuantity(product.id!, item.quantidade + 1);
      }
    } else {
      // Adiciona 1 unidade inicialmente
      if (product.quantidade > 0) {
        state = [
          ...state,
          SaleItem(
            product: product,
            quantidade: 1,
            descontoPercentual: 0.0,
            precoVendaEditado: product.valor,
          )
        ];
      }
    }
  }

  void removeProduct(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateItemQuantity(int productId, int newQuantity) {
    state = state.map((item) {
      if (item.product.id == productId) {
        return SaleItem(
          product: item.product,
          quantidade: newQuantity,
          descontoPercentual: item.descontoPercentual,
          precoVendaEditado: item.precoVendaEditado,
        );
      }
      return item;
    }).toList();
  }

  void updateItemDiscount(int productId, double newDiscount) {
    state = state.map((item) {
      if (item.product.id == productId) {
        return SaleItem(
          product: item.product,
          quantidade: item.quantidade,
          descontoPercentual: newDiscount,
          precoVendaEditado: item.precoVendaEditado,
        );
      }
      return item;
    }).toList();
  }

  void updateItemPrice(int productId, double newPrice) {
    state = state.map((item) {
      if (item.product.id == productId) {
        return SaleItem(
          product: item.product,
          quantidade: item.quantidade,
          descontoPercentual: item.descontoPercentual,
          precoVendaEditado: newPrice,
        );
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<SaleItem>>((ref) {
  return CartNotifier();
});

// Calcula o valor total do carrinho
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.subtotal);
});
