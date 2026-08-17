import '../entities/management.dart';
import '../repositories/management_repository.dart';

class GetFinancialSummaryUseCase {
  final ManagementRepository repository;
  GetFinancialSummaryUseCase(this.repository);

  Future<FinancialSummary> call(DateTime start, DateTime end) async {
    return await repository.getSummary(start, end);
  }
}

class GetExpensesUseCase {
  final ManagementRepository repository;
  GetExpensesUseCase(this.repository);

  Future<List<Expense>> call(DateTime start, DateTime end) async {
    return await repository.getExpenses(start, end);
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

  Future<List<SaleTransaction>> call(DateTime start, DateTime end) async {
    return await repository.getSalesTransactions(start, end);
  }
}

class GetSaleDetailsUseCase {
  final ManagementRepository repository;
  GetSaleDetailsUseCase(this.repository);

  Future<List<SaleItemDetail>> call(String compraId) async {
    return await repository.getSaleDetails(compraId);
  }
}
