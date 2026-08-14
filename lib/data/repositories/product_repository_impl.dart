import '../../core/database/database_helper.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<List<Product>> getProducts() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('produtos', orderBy: 'id DESC');
    
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  @override
  Future<void> addProduct(Product product) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('produtos', product.toMap());
  }

  @override
  Future<void> deleteProduct(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'produtos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
