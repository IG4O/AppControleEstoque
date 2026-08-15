import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/management.dart';
import '../providers/auth_provider.dart';
import '../providers/management_provider.dart';

class GerenciamentoScreen extends ConsumerWidget {
  const GerenciamentoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final selectedDate = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(financialSummaryProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final salesAsync = ref.watch(salesTransactionsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Financeiro'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
              onPressed: () {
                ref.invalidate(financialSummaryProvider);
                ref.invalidate(expensesProvider);
                ref.invalidate(salesTransactionsProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Filtrar Mês',
              onPressed: () => _selectMonth(context, ref, selectedDate),
            )
          ],
        ),
        body: Column(
          children: [
            // TOPO: Mês Selecionado
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                DateFormat('MMMM yyyy', 'pt_BR').format(selectedDate).toUpperCase(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            
            // TOPO: Cartões de Resumo Financeiro
            summaryAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
              error: (err, stack) => Padding(padding: const EdgeInsets.all(16.0), child: Text('Erro: $err')),
              data: (summary) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Faturamento', summary.faturamentoBruto, Colors.blue, currencyFormatter)),
                    Expanded(child: _buildSummaryCard('Gastos + COGS', summary.despesasAdicionais + summary.custoProdutosVendidos, Colors.red, currencyFormatter)),
                    Expanded(child: _buildSummaryCard('Lucro Líquido', summary.lucroLiquido, summary.lucroLiquido >= 0 ? Colors.green : Colors.orange, currencyFormatter)),
                  ],
                ),
              ),
            ),

            const Divider(),
            
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.money_off), text: 'Despesas'),
                Tab(icon: Icon(Icons.point_of_sale), text: 'Vendas'),
              ],
            ),

            // CORPO: Abas
            Expanded(
              child: TabBarView(
                children: [
                  _buildExpensesTab(expensesAsync, currencyFormatter, ref),
                  _buildSalesTab(salesAsync, currencyFormatter, context),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddExpenseDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Lançar Gasto'),
        ),
      ),
    );
  }

  Widget _buildExpensesTab(AsyncValue<List<Expense>> expensesAsync, NumberFormat currencyFormatter, WidgetRef ref) {
    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(child: Text('Nenhuma despesa registrada neste mês.'));
        }
        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final e = expenses[index];
            return ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.money_off, color: Colors.white)),
              title: Text(e.descricao),
              subtitle: Text(e.dataGasto != null ? _formatDate(e.dataGasto!) : ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currencyFormatter.format(e.valor), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => _confirmDeleteExpense(context, ref, e),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSalesTab(AsyncValue<List<SaleTransaction>> salesAsync, NumberFormat currencyFormatter, BuildContext context) {
    return salesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (sales) {
        if (sales.isEmpty) {
          return const Center(child: Text('Nenhuma venda registrada neste mês.'));
        }
        return ListView.builder(
          itemCount: sales.length,
          itemBuilder: (context, index) {
            final sale = sales[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.shopping_cart_checkout, color: Colors.white)),
                title: Text('Venda #${sale.compraId.substring(0, 8)}...'),
                subtitle: Text('Data: ${_formatDateTime(sale.dataVenda)}\nVendedor: ${sale.usuario}'),
                isThreeLine: true,
                trailing: Text(currencyFormatter.format(sale.total), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                onTap: () => _showSaleDetailsModal(context, sale),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color, NumberFormat formatter) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              formatter.format(value),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
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

  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _selectMonth(BuildContext context, WidgetRef ref, DateTime initialDate) async {
    // Para simplificar, usamos o DatePicker nativo restrito ao dia 1
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecione qualquer dia do mês desejado',
    );
    if (picked != null) {
      ref.read(selectedMonthProvider.notifier).state = DateTime(picked.year, picked.month);
    }
  }

  void _confirmDeleteExpense(BuildContext context, WidgetRef ref, Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Despesa'),
        content: Text('Deseja excluir a despesa "${expense.descricao}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(expensesProvider.notifier).deleteExpense(expense.id!);
              Navigator.of(ctx).pop();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AddExpenseModal(ref: ref),
    );
  }

  void _showSaleDetailsModal(BuildContext context, SaleTransaction sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SaleDetailsSheet(sale: sale);
      },
    );
  }
}

class _SaleDetailsSheet extends ConsumerWidget {
  final SaleTransaction sale;

  const _SaleDetailsSheet({required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsyncValue = ref.watch(saleDetailsProvider(sale.compraId));
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Detalhes da Venda #${sale.compraId.substring(0, 8)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(sale.dataVenda).toLocal())}'),
            Text('Vendedor: ${sale.usuario}'),
            const Divider(height: 32),
            const Text(
              'Itens Vendidos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: detailsAsyncValue.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('Nenhum item encontrado.'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.produtoNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Qtd: ${item.quantidade} | Desc: ${item.desconto.toStringAsFixed(0)}%',
                        ),
                        trailing: Text(
                          currencyFormatter.format(item.totalVenda),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erro: $err')),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total da Nota:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormatter.format(sale.total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExpenseModal extends StatefulWidget {
  final WidgetRef ref;
  const _AddExpenseModal({required this.ref});

  @override
  State<_AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<_AddExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  String descricao = '';
  double valor = 0.0;
  bool isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      final currentUser = widget.ref.read(currentUserProvider);

      final newExpense = Expense(
        descricao: descricao,
        valor: valor,
        usuario: currentUser?.email,
        dataGasto: DateTime.now().toUtc().subtract(const Duration(hours: 3)).toIso8601String(),
      );

      try {
        await widget.ref.read(expensesProvider.notifier).addExpense(newExpense);
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Lançar Gasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descrição (Ex: Conta de Luz)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
                onSaved: (v) => descricao = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Valor (R\$)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null ? 'Inválido' : null,
                onSaved: (v) => valor = double.parse(v ?? '0'),
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
    );
  }
}
