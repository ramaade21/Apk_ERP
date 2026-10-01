import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/utils/purchase_calculator.dart';
import '../models/purchase.dart';

class PurchaseRepository {
  final DatabaseHelper _helper;
  PurchaseRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  Future<List<Purchase>> list({String query = '', DateTime? date}) async {
    final db = await _helper.database;
    final where = <String>[];
    final args = <Object?>[];
    final q = query.trim();
    if (q.isNotEmpty) {
      where.add('(purchase_number LIKE ? OR supplier LIKE ?)');
      args
        ..add('%$q%')
        ..add('%$q%');
    }
    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day + 1);
      where.add('purchase_date >= ? AND purchase_date < ?');
      args
        ..add(start.toIso8601String())
        ..add(end.toIso8601String());
    }
    final rows = await db.query(
      'purchases',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'purchase_date DESC, id DESC',
    );
    return rows.map(Purchase.fromMap).toList();
  }

  Future<List<PurchaseItem>> items(int purchaseId) async {
    final db = await _helper.database;
    final rows = await db.rawQuery(
      'SELECT pi.*, r.name AS material_name, r.unit AS unit '
      'FROM purchase_items pi JOIN raw_materials r ON r.id = pi.raw_material_id '
      'WHERE pi.purchase_id = ? ORDER BY pi.id',
      [purchaseId],
    );
    return rows.map(PurchaseItem.fromMap).toList();
  }

  /// Simpan pembelian dan tambahkan stok bahan dalam satu transaksi.
  Future<int> create({
    String? supplier,
    required DateTime date,
    required List<PurchaseLine> lines,
    String? notes,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError('Pembelian harus memiliki minimal satu bahan');
    }
    final total = PurchaseCalculator.total(lines.map((l) => l.subtotal));
    final db = await _helper.database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final number = await _nextNumber(txn, date);
      final id = await txn.insert('purchases', {
        'purchase_number': number,
        'supplier': supplier,
        'purchase_date': date.toIso8601String(),
        'total': total,
        'notes': notes,
        'created_at': now,
        'updated_at': now,
      });
      for (final l in lines) {
        await txn.insert('purchase_items', {
          'purchase_id': id,
          'raw_material_id': l.materialId,
          'quantity': l.quantity,
          'price': l.price,
          'subtotal': l.subtotal,
        });
        await txn.rawUpdate(
          'UPDATE raw_materials SET stock = stock + ?, updated_at = ? WHERE id = ?',
          [l.quantity, now, l.materialId],
        );
      }
      return id;
    });
  }

  /// Hapus pembelian dan kembalikan stok (tidak kurang dari 0).
  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final items = await txn.query('purchase_items',
          where: 'purchase_id = ?', whereArgs: [id]);
      for (final it in items) {
        await txn.rawUpdate(
          'UPDATE raw_materials SET stock = MAX(0, stock - ?), updated_at = ? '
          'WHERE id = ?',
          [it['quantity'], now, it['raw_material_id']],
        );
      }
      await txn.delete('purchases', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<String> _nextNumber(DatabaseExecutor txn, DateTime date) async {
    final prefix = 'PB-${DateFormat('yyyyMMdd').format(date)}-';
    final count = Sqflite.firstIntValue(await txn.rawQuery(
            'SELECT COUNT(*) FROM purchases WHERE purchase_number LIKE ?',
            ['$prefix%'])) ??
        0;
    var seq = count + 1;
    while (true) {
      final candidate = '$prefix${seq.toString().padLeft(3, '0')}';
      final exists = Sqflite.firstIntValue(await txn.rawQuery(
              'SELECT COUNT(*) FROM purchases WHERE purchase_number = ?',
              [candidate])) ??
          0;
      if (exists == 0) return candidate;
      seq++;
    }
  }
}
