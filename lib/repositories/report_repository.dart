import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/utils/report_periods.dart';
import '../models/report.dart';

class ReportRepository {
  final DatabaseHelper _helper;
  ReportRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  static final _key = DateFormat('yyyy-MM-dd');

  /// Ringkasan per hari untuk seluruh tanggal di [range] (hari kosong = 0).
  Future<List<DaySummary>> daily(DateRange range) async {
    final db = await _helper.database;
    final s = range.start.toIso8601String();
    final e = range.end.toIso8601String();

    final sales = await db.rawQuery(
      'SELECT substr(transaction_date, 1, 10) AS d, '
      'COALESCE(SUM(total), 0) AS revenue, COALESCE(SUM(total_cost), 0) AS cogs, '
      'COUNT(*) AS cnt FROM sales '
      'WHERE transaction_date >= ? AND transaction_date < ? GROUP BY d',
      [s, e],
    );
    final purchases = await db.rawQuery(
      'SELECT substr(purchase_date, 1, 10) AS d, COALESCE(SUM(total), 0) AS amount '
      'FROM purchases WHERE purchase_date >= ? AND purchase_date < ? GROUP BY d',
      [s, e],
    );
    final expenses = await db.rawQuery(
      'SELECT substr(expense_date, 1, 10) AS d, COALESCE(SUM(amount), 0) AS amount '
      'FROM expenses WHERE expense_date >= ? AND expense_date < ? GROUP BY d',
      [s, e],
    );

    final salesByDay = {for (final r in sales) r['d'] as String: r};
    final purchasesByDay = {
      for (final r in purchases) r['d'] as String: r['amount'] as int
    };
    final expensesByDay = {
      for (final r in expenses) r['d'] as String: r['amount'] as int
    };

    return [
      for (final date in range.dates)
        () {
          final k = _key.format(date);
          final sale = salesByDay[k];
          return DaySummary(
            date: date,
            revenue: (sale?['revenue'] as int?) ?? 0,
            cogs: (sale?['cogs'] as int?) ?? 0,
            transactions: (sale?['cnt'] as int?) ?? 0,
            purchases: purchasesByDay[k] ?? 0,
            operational: expensesByDay[k] ?? 0,
          );
        }(),
    ];
  }

  Future<PeriodSummary> summary(DateRange range) async {
    final days = await daily(range);
    final db = await _helper.database;
    final customers = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(DISTINCT customer_id) FROM sales '
          'WHERE customer_id IS NOT NULL '
          'AND transaction_date >= ? AND transaction_date < ?',
          [range.start.toIso8601String(), range.end.toIso8601String()],
        )) ??
        0;
    return PeriodSummary.fromDays(days, customers: customers);
  }

  /// Penjualan per produk, terlaris di atas.
  Future<List<ProductSales>> productSales(DateRange range, {int? limit}) async {
    final db = await _helper.database;
    final rows = await db.rawQuery(
      'SELECT p.name AS name, SUM(si.quantity) AS qty, '
      'SUM(si.subtotal) AS revenue, SUM(si.cost_total) AS cost '
      'FROM sale_items si '
      'JOIN sales s ON s.id = si.sale_id '
      'JOIN products p ON p.id = si.product_id '
      'WHERE s.transaction_date >= ? AND s.transaction_date < ? '
      'GROUP BY p.id, p.name ORDER BY qty DESC, p.name'
      '${limit == null ? '' : ' LIMIT $limit'}',
      [range.start.toIso8601String(), range.end.toIso8601String()],
    );
    return rows
        .map((r) => ProductSales(
              name: r['name'] as String,
              quantity: r['qty'] as int,
              revenue: r['revenue'] as int,
              cost: r['cost'] as int,
            ))
        .toList();
  }
}
