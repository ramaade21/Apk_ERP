import '../core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

import '../models/customer.dart';

class CustomerStats {
  final int saleCount;
  final int saleTotal;
  final int orderCount;
  const CustomerStats({
    this.saleCount = 0,
    this.saleTotal = 0,
    this.orderCount = 0,
  });
}

class CustomerRepository {
  final DatabaseHelper _helper;
  CustomerRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  /// Cari berdasarkan nama, nomor HP, atau alamat.
  Future<List<Customer>> search([String query = '']) async {
    final db = await _helper.database;
    final q = query.trim();
    final rows = await db.query(
      'customers',
      where: q.isEmpty ? null : 'name LIKE ? OR phone LIKE ? OR address LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%', '%$q%'],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> insert(Customer c) async {
    final db = await _helper.database;
    return db.insert('customers', c.toMap());
  }

  Future<void> update(Customer c) async {
    final db = await _helper.database;
    await db.update('customers', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<CustomerStats> stats(int customerId) async {
    final db = await _helper.database;
    final sales = await db.rawQuery(
        'SELECT COUNT(*) AS cnt, COALESCE(SUM(total), 0) AS sum '
        'FROM sales WHERE customer_id = ?',
        [customerId]);
    final orderCount = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM orders WHERE customer_id = ?',
            [customerId])) ??
        0;
    return CustomerStats(
      saleCount: sales.first['cnt'] as int,
      saleTotal: sales.first['sum'] as int,
      orderCount: orderCount,
    );
  }
}
