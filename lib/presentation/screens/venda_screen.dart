import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/management_provider.dart';
import '../../domain/entities/sale.dart';

class VendaScreen extends ConsumerStatefulWidget {
  const VendaScreen({super.key});

  @override
  ConsumerState<VendaScreen> createState() => _VendaScreenState();
}

class _VendaScreenState extends ConsumerState<VendaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _finishSale() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione produtos ao carrinho!')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final useCase = ref.read(registerSaleUseCaseProvider);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      await useCase(cart, user?.email ?? 'Desconhecido');
      
      if (mounted) Navigator.of(context).pop(); // Close loading

      // Limpa o carrinho e recarrega produtos para atualizar o estoque
      ref.read(cartProvider.notifier).clearCart();
      ref.read(productsProvider.notifier).loadProducts();
      
      // Invalida o dashboard de gerenciamento para atualizar em tempo real
      ref.invalidate(financialSummaryProvider);
      ref.invalidate(salesTransactionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venda registrada com sucesso!'), backgroundColor: Colors.green),
        );
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(icon: Icon(Icons.list), text: 'Produtos'),
            Tab(
              icon: Badge(
                label: Text(cart.length.toString()),
                isLabelVisible: cart.isNotEmpty,
                child: const Icon(Icons.shopping_cart),
              ),
              text: 'Carrinho',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Aba 1: Lista de Produtos para Selecionar
          _buildProductList(currencyFormat),
          // Aba 2: Carrinho de Compras
          _buildCart(currencyFormat, cart, total),
        ],
      ),
    );
  }

  Widget _buildProductList(NumberFormat formatter) {
    final productsState = ref.watch(productsProvider);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar produto...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: productsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erro: $err')),
            data: (products) {
              final filtered = products.where((p) => 
                p.nome.toLowerCase().contains(_searchQuery)
              ).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('Nenhum produto encontrado.'));
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, index) {
                  final p = filtered[index];
                  final outOfStock = p.quantidade <= 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.nome, style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: outOfStock ? Colors.grey : Colors.black,
                                  decoration: outOfStock ? TextDecoration.lineThrough : null,
                                )),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: outOfStock ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Estoque: ${p.quantidade}',
                                        style: TextStyle(
                                          color: outOfStock ? Colors.red : Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(formatter.format(p.valor), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: outOfStock ? null : () {
                              ref.read(cartProvider.notifier).addProduct(p);
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${p.nome} adicionado.'), duration: const Duration(seconds: 1)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCart(NumberFormat formatter, cart, double total) {
    if (cart.isEmpty) {
      return const Center(child: Text('O carrinho está vazio.'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cart.length,
            itemBuilder: (ctx, index) {
              final item = cart[index];
              return CartItemWidget(item: item, formatter: formatter);
            },
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 16)),
                    Text(formatter.format(total), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar Venda'),
                  onPressed: _finishSale,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CartItemWidget extends ConsumerStatefulWidget {
  final SaleItem item;
  final NumberFormat formatter;

  const CartItemWidget({super.key, required this.item, required this.formatter});

  @override
  ConsumerState<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends ConsumerState<CartItemWidget> {
  late TextEditingController _discountController;
  late TextEditingController _finalPriceController;
  final FocusNode _discountFocus = FocusNode();
  final FocusNode _finalPriceFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(text: widget.item.descontoPercentual > 0 ? widget.item.descontoPercentual.toStringAsFixed(1) : '');
    _finalPriceController = TextEditingController(text: widget.item.precoUnidadeFinal.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se mudou externamente (ex: o usuário digitou no outro campo ou trocou a chave de prazo)
    if (widget.item.descontoPercentual != oldWidget.item.descontoPercentual && !_discountFocus.hasFocus) {
       _discountController.text = widget.item.descontoPercentual > 0 ? widget.item.descontoPercentual.toStringAsFixed(1) : '';
    }
    if (widget.item.precoUnidadeFinal != oldWidget.item.precoUnidadeFinal && !_finalPriceFocus.hasFocus) {
       _finalPriceController.text = widget.item.precoUnidadeFinal.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _discountFocus.dispose();
    _finalPriceFocus.dispose();
    _discountController.dispose();
    _finalPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final formatter = widget.formatter;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item.product.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => ref.read(cartProvider.notifier).removeProduct(item.product.id!),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Qtd: '),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: item.quantidade > 1 
                    ? () => ref.read(cartProvider.notifier).updateItemQuantity(item.product.id!, item.quantidade - 1)
                    : null,
                ),
                Text('${item.quantidade}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: item.quantidade < item.product.quantidade
                    ? () => ref.read(cartProvider.notifier).updateItemQuantity(item.product.id!, item.quantidade + 1)
                    : null,
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Sub: ${formatter.format(item.subtotal)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    if (item.isPrazo && item.parcelas > 1)
                      Text('${item.parcelas}x de ${formatter.format(item.valorParcela)}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                const Text('Tipo: '),
                Switch(
                  value: item.isPrazo,
                  onChanged: (val) {
                    ref.read(cartProvider.notifier).toggleItemPrazo(item.product.id!, val);
                  },
                ),
                Text(item.isPrazo ? 'A Prazo' : 'À Vista', style: TextStyle(fontWeight: FontWeight.bold, color: item.isPrazo ? Colors.blue : Colors.green)),
                if (item.isPrazo) ...[
                  const SizedBox(width: 8),
                  const Text('Parc: '),
                  DropdownButton<int>(
                    value: item.parcelas,
                    isDense: true,
                    items: List.generate(12, (index) => index + 1).map((p) {
                      return DropdownMenuItem(value: p, child: Text('${p}x'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(cartProvider.notifier).updateItemParcelas(item.product.id!, val);
                      }
                    },
                  ),
                ] else ...[
                  const Spacer(),
                  Text('Preço Base: ${formatter.format(item.precoVendaEditado)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _discountFocus,
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Desconto %', isDense: true),
                    onChanged: (val) {
                      final d = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                      ref.read(cartProvider.notifier).updateItemDiscount(item.product.id!, d);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    focusNode: _finalPriceFocus,
                    controller: _finalPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor Final Un.', isDense: true),
                    onChanged: (val) {
                      // Se o usuário apagar tudo, consideramos 0 para evitar quebra, mas preferencialmente aguardamos nova digitação
                      if (val.trim().isEmpty) return;
                      final p = double.tryParse(val.replaceAll(',', '.')) ?? item.precoUnidadeFinal;
                      ref.read(cartProvider.notifier).updateItemFinalPrice(item.product.id!, p);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
