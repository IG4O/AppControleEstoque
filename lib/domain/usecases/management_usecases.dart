import '../entities/management.dart';
import '../repositories/management_repository.dart';

class GetFinancialSummaryUseCase {
  final ManagementRepository repository;
  GetFinancialSummaryUseCase(this.repository);

  Future<FinancialSummary> call(int month, int year) async {
    return await repository.getSummary(month, year);
  }
}

class GetExpensesUseCase {
  final ManagementRepository repository;
  GetExpensesUseCase(this.repository);

  Future<List<Expense>> call(int month, int year) async {
    return await repository.getExpenses(month, year);
  }
}

class AddExpenseUseCase {
  final ManagementRepository repository;
  AddExpenseUseCase(this.repository);

  Future<void> call(Expense expense) async {
    if (expense.descricao.isEmpty) throw Exception('A descrição é obrigatória.');
    if (expense.valor <= 0) throw Exception('O valor deve ser maior que zero.');

    await repository.addExpense(expense);
  }
}

class DeleteExpenseUseCase {
  final ManagementRepository repository;
  DeleteExpenseUseCase(this.repository);

  Future<void> call(int id) async {
    await repository.deleteExpense(id);
  }
}

class GetSalesTransactionsUseCase {
  final ManagementRepository repository;
  GetSalesTransactionsUseCase(this.repository);

  Future<List<SaleTransaction>> call(int month, int year) async {
    return await repository.getSalesTransactions(month, year);
  }
}
