import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/utils/sale_calculator.dart';
import '../models/sale.dart';

class SaleRepository {
  final DatabaseHelper _helper;
  SaleRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  Future<List<Sale>> list({
    String query = '',
    DateTime? date,
    int? customerId,
  }) async {
    final db = await _helper.database;
    final where = <String>[];
    final args = <Object?>[];
    final q = query.trim();
    if (q.isNotEmpty) {
      where.add('(s.invoice_number LIKE ? OR c.name LIKE ?)');
      args
        ..add('%$q%')
        ..add('%$q%');
    }
    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day + 1);
      where.add('s.transaction_date >= ? AND s.transaction_date < ?');
      args
        ..add(start.toIso8601String())
        ..add(end.toIso8601String());
    }
    if (customerId != null) {
      where.add('s.customer_id = ?');
      args.add(customerId);
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery(
      'SELECT s.*, c.name AS customer_name FROM sales s '
      'LEFT JOIN customers c ON c.id = s.customer_id '
      '$whereSql ORDER BY s.transaction_date DESC, s.id DESC',
      args,
    );
    return rows.map(Sale.fromMap).toList();
  }

  Future<List<SaleItem>> items(int saleId) async {
    final db = await _helper.database;
    final rows = await db.rawQuery(
      'SELECT si.*, p.name AS product_name FROM sale_items si '
      'JOIN products p ON p.id = si.product_id '
      'WHERE si.sale_id = ? ORDER BY si.id',
      [saleId],
    );
    return rows.map(SaleItem.fromMap).toList();
  }

  /// Simpan transaksi + item dalam satu transaksi database.
  Future<int> create({
    int? customerId,
    required DateTime date,
    required String orderType,
    required List<SaleLine> lines,
    int discount = 0,
    String? notes,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError('Transaksi harus memiliki minimal satu produk');
    }
    if (discount < 0) throw ArgumentError('Diskon tidak boleh negatif');
    final items = lines.map((l) => l.item).toList();
    final subtotal = SaleCalculator.subtotal(items);
    final total = SaleCalculator.total(items, discount: discount);
    if (total < 0) throw ArgumentError('Total transaksi tidak valid');
    final totalCost = SaleCalculator.totalCost(items);
    final profit = SaleCalculator.profit(items, discount: discount);

    final db = await _helper.database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final invoice = await _nextInvoice(txn, date);
      final saleId = await txn.insert('sales', {
        'invoice_number': invoice,
        'customer_id': customerId,
        'transaction_date': date.toIso8601String(),
        'order_type': orderType,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'total_cost': totalCost,
        'profit': profit,
        'notes': notes,
        'created_at': now,
        'updated_at': now,
      });
      for (final l in lines) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': l.productId,
          'quantity': l.item.quantity,
          'price': l.item.price,
          'cost_price': l.item.cost,
          'subtotal': l.item.subtotal,
          'cost_total': l.item.costTotal,
          'profit': l.item.profit,
        });
      }
      return saleId;
    });
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> _nextInvoice(DatabaseExecutor txn, DateTime date) async {
    final prefix = 'INV-${DateFormat('yyyyMMdd').format(date)}-';
    final count = Sqflite.firstIntValue(await txn.rawQuery(
            'SELECT COUNT(*) FROM sales WHERE invoice_number LIKE ?',
            ['$prefix%'])) ??
        0;
    var seq = count + 1;
    while (true) {
      final candidate = '$prefix${seq.toString().padLeft(3, '0')}';
      final exists = Sqflite.firstIntValue(await txn.rawQuery(
              'SELECT COUNT(*) FROM sales WHERE invoice_number = ?',
              [candidate])) ??
          0;
      if (exists == 0) return candidate;
      seq++;
    }
  }
}
