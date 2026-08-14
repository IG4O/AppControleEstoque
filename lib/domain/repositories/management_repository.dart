import '../entities/management.dart';

abstract class ManagementRepository {
  Future<FinancialSummary> getSummary(int month, int year);
  Future<List<Expense>> getExpenses(int month, int year);
  Future<List<SaleTransaction>> getSalesTransactions(int month, int year);
  Future<void> addExpense(Expense expense);
  Future<void> deleteExpense(int id);
}
