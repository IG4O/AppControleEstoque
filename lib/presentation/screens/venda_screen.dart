import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';

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
        title: const Text('Ponto de Venda'),
        bottom: TabBar(
          controller: _tabController,
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

                  return ListTile(
                    title: Text(p.nome, style: TextStyle(
                      color: outOfStock ? Colors.grey : Colors.black,
                      decoration: outOfStock ? TextDecoration.lineThrough : null,
                    )),
                    subtitle: Text('Estoque: ${p.quantidade} | ${formatter.format(p.valor)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart, color: Colors.deepPurple),
                      onPressed: outOfStock ? null : () {
                        ref.read(cartProvider.notifier).addProduct(p);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${p.nome} adicionado.'), duration: const Duration(seconds: 1)),
                        );
                      },
                    ),
                    onTap: outOfStock ? null : () {
                      ref.read(cartProvider.notifier).addProduct(p);
                    },
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
                          Text('Sub: ${formatter.format(item.subtotal)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Desconto %', isDense: true),
                              onChanged: (val) {
                                final d = double.tryParse(val) ?? 0.0;
                                ref.read(cartProvider.notifier).updateItemDiscount(item.product.id!, d);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Preço Venda', isDense: true),
                              controller: TextEditingController(text: item.precoVendaEditado.toStringAsFixed(2))..selection = TextSelection.collapsed(offset: item.precoVendaEditado.toStringAsFixed(2).length),
                              onChanged: (val) {
                                final p = double.tryParse(val) ?? item.product.valor;
                                ref.read(cartProvider.notifier).updateItemPrice(item.product.id!, p);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          color: Colors.deepPurple.shade50,
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
                    Text(formatter.format(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
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
