import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/database/database_helper.dart';
import '../core/utils/csv.dart';
import '../core/utils/formatters.dart';
import '../core/utils/report_periods.dart';
import '../models/sale.dart';
import '../repositories/report_repository.dart';

/// Menyiapkan data laporan (baris-baris) dan menyimpannya sebagai file CSV.
class ExportService {
  final DatabaseHelper _helper;
  final ReportRepository _reports;
  ExportService([DatabaseHelper? helper, ReportRepository? reports])
      : _helper = helper ?? DatabaseHelper.instance,
        _reports = reports ?? ReportRepository();

  List<Object?> _bounds(DateRange r) =>
      [r.start.toIso8601String(), r.end.toIso8601String()];

  Future<File> saveCsv(String fileName, List<List<Object?>> rows) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    // BOM agar Excel membaca UTF-8 dengan benar
    await file.writeAsString('\uFEFF${Csv.encode(rows)}');
    return file;
  }

  /// Laporan harian/bulanan lengkap: ringkasan, rincian per hari, dan produk.
  Future<List<List<Object?>>> reportRows(DateRange r,
      {required String title, required bool includeDaily}) async {
    final s = await _reports.summary(r);
    final rows = <List<Object?>>[
      [title],
      [],
      ['Omzet', s.revenue],
      ['HPP', s.cogs],
      ['Pembelian bahan baku', s.purchases],
      ['Biaya operasional', s.operational],
      ['Laba kotor', s.grossProfit],
      [s.isLoss ? 'Rugi bersih' : 'Laba bersih', s.netProfit.abs()],
      ['Jumlah transaksi', s.transactions],
      ['Jumlah customer', s.customers],
    ];
    if (includeDaily) {
      final days = await _reports.daily(r);
      rows
        ..add([])
        ..add([
          'Tanggal',
          'Omzet',
          'HPP',
          'Pembelian bahan baku',
          'Operasional',
          'Laba kotor',
          'Laba bersih',
          'Transaksi',
        ]);
      for (final d in days) {
        rows.add([
          Fmt.date(d.date),
          d.revenue,
          d.cogs,
          d.purchases,
          d.operational,
          d.grossProfit,
          d.netProfit,
          d.transactions,
        ]);
      }
    }
    final products = await _reports.productSales(r);
    rows
      ..add([])
      ..add(['Produk', 'Qty terjual', 'Omzet', 'HPP', 'Laba']);
    for (final p in products) {
      rows.add([p.name, p.quantity, p.revenue, p.cost, p.profit]);
    }
    return rows;
  }

  Future<List<List<Object?>>> profitLossRows(DateRange r,
      {required String title}) async {
    final s = await _reports.summary(r);
    return [
      [title],
      [],
      ['Keterangan', 'Nominal'],
      ['Omzet', s.revenue],
      ['HPP', s.cogs],
      ['Laba kotor', s.grossProfit],
      ['Biaya operasional', s.operational],
      [s.isLoss ? 'Rugi bersih' : 'Laba bersih', s.netProfit.abs()],
      [],
      ['Pembelian bahan baku (informasi)', s.purchases],
    ];
  }

  Future<List<List<Object?>>> salesRows(DateRange r) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT s.*, c.name AS customer_name FROM sales s '
      'LEFT JOIN customers c ON c.id = s.customer_id '
      'WHERE s.transaction_date >= ? AND s.transaction_date < ? '
      'ORDER BY s.transaction_date, s.id',
      _bounds(r),
    );
    final rows = <List<Object?>>[
      [
        'No. Transaksi',
        'Tanggal',
        'Jam',
        'Customer',
        'Jenis pesanan',
        'Subtotal',
        'Diskon',
        'Total',
        'HPP',
        'Laba/Rugi',
        'Catatan',
      ],
    ];
    for (final m in result) {
      final s = Sale.fromMap(m);
      rows.add([
        s.invoiceNumber,
        Fmt.date(s.date),
        Fmt.time(s.date),
        s.customerName ?? 'Umum',
        s.orderType,
        s.subtotal,
        s.discount,
        s.total,
        s.totalCost,
        s.profit,
        s.notes ?? '',
      ]);
    }
    return rows;
  }

  Future<List<List<Object?>>> customerRows() async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT c.name AS name, c.phone AS phone, c.address AS address, '
      '(SELECT COUNT(*) FROM sales s WHERE s.customer_id = c.id) AS sale_count, '
      '(SELECT COALESCE(SUM(s.total), 0) FROM sales s WHERE s.customer_id = c.id) AS sale_total, '
      '(SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count, '
      '(SELECT MAX(s.transaction_date) FROM sales s WHERE s.customer_id = c.id) AS last_sale '
      'FROM customers c ORDER BY c.name COLLATE NOCASE',
    );
    final rows = <List<Object?>>[
      [
        'Nama',
        'WhatsApp',
        'Alamat',
        'Jumlah transaksi',
        'Total belanja',
        'Jumlah pesanan',
        'Transaksi terakhir',
      ],
    ];
    for (final m in result) {
      final last = m['last_sale'] as String?;
      rows.add([
        m['name'],
        m['phone'] ?? '',
        m['address'] ?? '',
        m['sale_count'],
        m['sale_total'],
        m['order_count'],
        last == null ? '' : Fmt.date(DateTime.parse(last)),
      ]);
    }
    return rows;
  }

  Future<List<List<Object?>>> purchaseRows(DateRange r) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT p.purchase_number AS number, p.purchase_date AS date, '
      'p.supplier AS supplier, m.name AS material, m.unit AS unit, '
      'pi.quantity AS qty, pi.price AS price, pi.subtotal AS subtotal '
      'FROM purchase_items pi '
      'JOIN purchases p ON p.id = pi.purchase_id '
      'JOIN raw_materials m ON m.id = pi.raw_material_id '
      'WHERE p.purchase_date >= ? AND p.purchase_date < ? '
      'ORDER BY p.purchase_date, p.id, pi.id',
      _bounds(r),
    );
    final rows = <List<Object?>>[
      [
        'No. Pembelian',
        'Tanggal',
        'Supplier',
        'Bahan',
        'Satuan',
        'Jumlah',
        'Harga',
        'Subtotal',
      ],
    ];
    for (final m in result) {
      rows.add([
        m['number'],
        Fmt.date(DateTime.parse(m['date'] as String)),
        m['supplier'] ?? '',
        m['material'],
        m['unit'],
        Fmt.qty(m['qty'] as num),
        m['price'],
        m['subtotal'],
      ]);
    }
    return rows;
  }

  Future<List<List<Object?>>> expenseRows(DateRange r) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT * FROM expenses WHERE expense_date >= ? AND expense_date < ? '
      'ORDER BY expense_date, id',
      _bounds(r),
    );
    final rows = <List<Object?>>[
      ['Tanggal', 'Kategori', 'Nama pengeluaran', 'Nominal', 'Keterangan'],
    ];
    for (final m in result) {
      rows.add([
        Fmt.date(DateTime.parse(m['expense_date'] as String)),
        m['category'],
        m['name'],
        m['amount'],
        m['notes'] ?? '',
      ]);
    }
    return rows;
  }
}
