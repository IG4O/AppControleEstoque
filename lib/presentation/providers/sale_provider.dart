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
            isPrazo: false,
            parcelas: 1,
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
        return item.copyWith(quantidade: newQuantity);
      }
      return item;
    }).toList();
  }

  void updateItemDiscount(int productId, double newDiscount) {
    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(descontoPercentual: newDiscount);
      }
      return item;
    }).toList();
  }

  void updateItemFinalPrice(int productId, double finalPrice) {
    state = state.map((item) {
      if (item.product.id == productId) {
        // Se o usuário digitou o valor final, calculamos qual é o desconto equivalente
        final basePrice = item.precoVendaEditado;
        if (basePrice <= 0) return item;
        
        final calculatedDiscount = ((basePrice - finalPrice) / basePrice) * 100;
        return item.copyWith(descontoPercentual: calculatedDiscount);
      }
      return item;
    }).toList();
  }

  void toggleItemPrazo(int productId, bool isPrazo) {
    state = state.map((item) {
      if (item.product.id == productId) {
        final newBasePrice = isPrazo ? item.product.valorPrazo : item.product.valor;
        return item.copyWith(
          isPrazo: isPrazo,
          precoVendaEditado: newBasePrice,
          parcelas: isPrazo ? item.parcelas : 1, // reseta para 1 se for a vista
        );
      }
      return item;
    }).toList();
  }

  void updateItemParcelas(int productId, int parcelas) {
    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(parcelas: parcelas);
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
