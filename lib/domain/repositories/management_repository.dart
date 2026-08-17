import '../entities/management.dart';

abstract class ManagementRepository {
  Future<FinancialSummary> getSummary(DateTime start, DateTime end);
  Future<List<Expense>> getExpenses(DateTime start, DateTime end);
  Future<List<SaleTransaction>> getSalesTransactions(DateTime start, DateTime end);
  Future<List<SaleItemDetail>> getSaleDetails(String compraId);
  Future<void> addExpense(Expense expense);
  Future<void> deleteExpense(int id);
}
