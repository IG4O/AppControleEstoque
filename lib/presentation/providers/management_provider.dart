import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/management_repository_impl.dart';
import '../../domain/entities/management.dart';
import '../../domain/repositories/management_repository.dart';
import '../../domain/usecases/management_usecases.dart';

final managementRepositoryProvider = Provider<ManagementRepository>((ref) {
  return ManagementRepositoryImpl();
});

final getFinancialSummaryUseCaseProvider = Provider<GetFinancialSummaryUseCase>((ref) {
  return GetFinancialSummaryUseCase(ref.watch(managementRepositoryProvider));
});

final getExpensesUseCaseProvider = Provider<GetExpensesUseCase>((ref) {
  return GetExpensesUseCase(ref.watch(managementRepositoryProvider));
});

final addExpenseUseCaseProvider = Provider<AddExpenseUseCase>((ref) {
  return AddExpenseUseCase(ref.watch(managementRepositoryProvider));
});

final deleteExpenseUseCaseProvider = Provider<DeleteExpenseUseCase>((ref) {
  return DeleteExpenseUseCase(ref.watch(managementRepositoryProvider));
});

final getSalesTransactionsUseCaseProvider = Provider<GetSalesTransactionsUseCase>((ref) {
  return GetSalesTransactionsUseCase(ref.watch(managementRepositoryProvider));
});

// Provedor para gerenciar o Mês/Ano selecionado (padrão: mês atual)
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// Provedor para carregar o Resumo Financeiro
final financialSummaryProvider = FutureProvider<FinancialSummary>((ref) async {
  final date = ref.watch(selectedMonthProvider);
  final useCase = ref.watch(getFinancialSummaryUseCaseProvider);
  return await useCase(date.month, date.year);
});

// Provedor para carregar as Vendas do mês (Relatório)
final salesTransactionsProvider = FutureProvider<List<SaleTransaction>>((ref) async {
  final date = ref.watch(selectedMonthProvider);
  final useCase = ref.watch(getSalesTransactionsUseCaseProvider);
  return await useCase(date.month, date.year);
});

// Provedor para gerenciar a lista de Despesas
final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  final date = ref.watch(selectedMonthProvider);
  return ExpensesNotifier(
    ref.watch(getExpensesUseCaseProvider),
    ref.watch(addExpenseUseCaseProvider),
    ref.watch(deleteExpenseUseCaseProvider),
    date.month,
    date.year,
    ref,
  );
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final GetExpensesUseCase _getExpenses;
  final AddExpenseUseCase _addExpense;
  final DeleteExpenseUseCase _deleteExpense;
  final int month;
  final int year;
  final Ref ref;

  ExpensesNotifier(
    this._getExpenses, 
    this._addExpense, 
    this._deleteExpense, 
    this.month, 
    this.year,
    this.ref,
  ) : super(const AsyncLoading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncLoading();
    try {
      final expenses = await _getExpenses(month, year);
      state = AsyncData(expenses);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _addExpense(expense);
      await loadExpenses();
      // Atualiza o resumo financeiro para refletir o novo gasto
      ref.invalidate(financialSummaryProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _deleteExpense(id);
      await loadExpenses();
      // Atualiza o resumo financeiro para refletir a exclusão
      ref.invalidate(financialSummaryProvider);
    } catch (e) {
      rethrow;
    }
  }
}
