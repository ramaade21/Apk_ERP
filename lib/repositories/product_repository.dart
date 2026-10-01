import '../core/database/database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseHelper _helper;
  ProductRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  Future<List<Product>> getAll({bool includeInactive = true}) async {
    final db = await _helper.database;
    final rows = await db.query(
      'products',
      where: includeInactive ? null : 'is_active = 1',
      orderBy: 'is_active DESC, category, name',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<int> insert(Product p) async {
    final db = await _helper.database;
    return db.insert('products', p.toMap());
  }

  Future<void> update(Product p) async {
    final db = await _helper.database;
    await db.update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> setActive(int id, bool active) async {
    final db = await _helper.database;
    await db.update(
      'products',
      {'is_active': active ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Jumlah porsi terjual per produk (id -> qty).
  Future<Map<int, int>> soldQuantities() async {
    final db = await _helper.database;
    final rows = await db.rawQuery(
        'SELECT product_id, SUM(quantity) AS qty FROM sale_items GROUP BY product_id');
    return {
      for (final r in rows) r['product_id'] as int: (r['qty'] as int?) ?? 0
    };
  }
}
