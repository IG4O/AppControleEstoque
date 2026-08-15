import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

class EstoqueScreen extends ConsumerWidget {
  const EstoqueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsProvider);
    final totalStock = ref.watch(totalStockValueProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      body: Column(
        children: [
          // Cabeçalho de Total
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total em Estoque:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormatter.format(totalStock),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Lista de Produtos
          Expanded(
            child: productsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erro: $err')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('Nenhum produto cadastrado.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: InkWell(
                        onTap: () => _showEditProductDialog(context, ref, p),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p.nome,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(context, ref, p),
                                ),
                              ],
                            ),
                            if (p.marca != null && p.marca != '-') 
                              Text('Marca: ${p.marca}', style: TextStyle(color: Colors.grey.shade700)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Qtd: ${p.quantidade}'),
                                Text('Custo: ${currencyFormatter.format(p.custo)}'),
                                Text(
                                  'Venda: ${currencyFormatter.format(p.valor)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Adicionado em: ${p.dataRegistro != null ? _formatDate(p.dataRegistro!) : '-'}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo Produto'),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoString;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text('Tem certeza que deseja excluir "${product.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (product.id != null) {
                ref.read(productsProvider.notifier).deleteProduct(product.id!);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AddProductModal(ref: ref),
    );
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => _EditProductModal(ref: ref, product: product),
    );
  }
}

class _AddProductModal extends StatefulWidget {
  final WidgetRef ref;
  const _AddProductModal({required this.ref});

  @override
  State<_AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<_AddProductModal> {
  final _formKey = GlobalKey<FormState>();
  String nome = '';
  String marca = '';
  int quantidade = 0;
  double custo = 0.0;
  double valor = 0.0;
  bool isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      final currentUser = widget.ref.read(currentUserProvider);

      final newProduct = Product(
        nome: nome,
        marca: marca.isEmpty ? '-' : marca,
        quantidade: quantidade,
        custo: custo,
        valor: valor,
        usuario: currentUser?.email,
        dataRegistro: DateTime.now().toUtc().subtract(const Duration(hours: 3)).toIso8601String(),
      );

      try {
        await widget.ref.read(productsProvider.notifier).addProduct(newProduct);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Novo Produto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                  onSaved: (v) => nome = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Marca (Opcional)', border: OutlineInputBorder()),
                  onSaved: (v) => marca = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null ? 'Inválido' : null,
                  onSaved: (v) => quantidade = int.parse(v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Custo', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Inválido' : null,
                        onSaved: (v) => custo = double.parse(v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Preço Venda', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Inválido' : null,
                        onSaved: (v) => valor = double.parse(v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProductModal extends StatefulWidget {
  final WidgetRef ref;
  final Product product;
  const _EditProductModal({required this.ref, required this.product});

  @override
  State<_EditProductModal> createState() => _EditProductModalState();
}

class _EditProductModalState extends State<_EditProductModal> {
  final _formKey = GlobalKey<FormState>();
  late String nome;
  late String marca;
  late int quantidade;
  late double custo;
  late double valor;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nome = widget.product.nome;
    marca = widget.product.marca ?? '';
    quantidade = widget.product.quantidade;
    custo = widget.product.custo;
    valor = widget.product.valor;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      final updatedProduct = widget.product.copyWith(
        nome: nome,
        marca: marca.isEmpty ? '-' : marca,
        quantidade: quantidade,
        custo: custo,
        valor: valor,
      );

      try {
        await widget.ref.read(productsProvider.notifier).updateProduct(updatedProduct);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Editar Produto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: nome,
                  decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                  onSaved: (v) => nome = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: marca == '-' ? '' : marca,
                  decoration: const InputDecoration(labelText: 'Marca (Opcional)', border: OutlineInputBorder()),
                  onSaved: (v) => marca = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: quantidade.toString(),
                  decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null ? 'Inválido' : null,
                  onSaved: (v) => quantidade = int.parse(v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: custo.toString(),
                        decoration: const InputDecoration(labelText: 'Custo', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Inválido' : null,
                        onSaved: (v) => custo = double.parse(v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: valor.toString(),
                        decoration: const InputDecoration(labelText: 'Preço Venda', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Inválido' : null,
                        onSaved: (v) => valor = double.parse(v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
