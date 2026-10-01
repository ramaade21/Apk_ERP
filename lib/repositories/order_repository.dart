import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/customer_order.dart';
import '../models/sale.dart';

class OrderRepository {
  final DatabaseHelper _helper;
  OrderRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  /// Cari berdasarkan nama, nomor WhatsApp, atau alamat.
  Future<List<CustomerOrder>> list({
    String query = '',
    String? status,
    int? customerId,
  }) async {
    final db = await _helper.database;
    final where = <String>[];
    final args = <Object?>[];
    final q = query.trim();
    if (q.isNotEmpty) {
      where.add(
          '(c.name LIKE ? OR c.phone LIKE ? OR o.address LIKE ? OR c.address LIKE ?)');
      for (var i = 0; i < 4; i++) {
        args.add('%$q%');
      }
    }
    if (status != null) {
      where.add('o.status = ?');
      args.add(status);
    }
    if (customerId != null) {
      where.add('o.customer_id = ?');
      args.add(customerId);
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery(
      'SELECT o.*, c.name AS customer_name, c.phone AS customer_phone '
      'FROM orders o LEFT JOIN customers c ON c.id = o.customer_id '
      '$whereSql ORDER BY o.order_date DESC, o.id DESC',
      args,
    );
    return rows.map(CustomerOrder.fromMap).toList();
  }

  Future<List<OrderItem>> items(int orderId) async {
    final db = await _helper.database;
    final rows = await db.rawQuery(
      'SELECT oi.*, p.name AS product_name FROM order_items oi '
      'JOIN products p ON p.id = oi.product_id '
      'WHERE oi.order_id = ? ORDER BY oi.id',
      [orderId],
    );
    return rows.map(OrderItem.fromMap).toList();
  }

  Future<int> create({
    required int customerId,
    required DateTime date,
    required String orderType,
    required String status,
    required List<SaleLine> lines,
    String? address,
    String? notes,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError('Pesanan harus memiliki minimal satu produk');
    }
    final total = lines.fold<int>(0, (s, l) => s + l.item.subtotal);
    final db = await _helper.database;
    return db.transaction((txn) async {
      final orderId = await txn.insert('orders', {
        'customer_id': customerId,
        'order_date': date.toIso8601String(),
        'status': status,
        'order_type': orderType,
        'total': total,
        'address': address,
        'notes': notes,
      });
      for (final l in lines) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': l.productId,
          'quantity': l.item.quantity,
          'price': l.item.price,
          'subtotal': l.item.subtotal,
        });
      }
      return orderId;
    });
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _helper.database;
    await db.update('orders', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<OrderStats> stats() async {
    final db = await _helper.database;
    final totalOrders = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM orders')) ??
        0;
    final totalCustomers = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM customers')) ??
        0;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final newCustomers = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM customers WHERE created_at >= ?',
            [monthStart])) ??
        0;
    final rows = await db.rawQuery(
      'SELECT c.id AS id, c.name AS name, COUNT(o.id) AS cnt '
      'FROM customers c JOIN orders o ON o.customer_id = c.id '
      'GROUP BY c.id, c.name ORDER BY cnt DESC, c.name LIMIT 5',
    );
    return OrderStats(
      totalOrders: totalOrders,
      totalCustomers: totalCustomers,
      newCustomersThisMonth: newCustomers,
      topCustomers: rows
          .map((r) => CustomerOrderCount(
              r['id'] as int, r['name'] as String, r['cnt'] as int))
          .toList(),
    );
  }
}
