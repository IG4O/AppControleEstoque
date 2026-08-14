import '../entities/sale.dart';

abstract class SaleRepository {
  Future<void> registerSale(Sale sale);
}
