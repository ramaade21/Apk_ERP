import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/utils/purchase_calculator.dart';
import '../models/raw_material.dart';

class RawMaterialRepository {
  final DatabaseHelper _helper;
  RawMaterialRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  /// Cari berdasarkan nama atau kategori.
  Future<List<RawMaterial>> list([String query = '']) async {
    final db = await _helper.database;
    final q = query.trim();
    final rows = await db.query(
      'raw_materials',
      where: q.isEmpty ? null : 'name LIKE ? OR category LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(RawMaterial.fromMap).toList();
  }

  Future<int> insert(RawMaterial m) async {
    final db = await _helper.database;
    return db.insert('raw_materials', m.toMap());
  }

  Future<void> update(RawMaterial m) async {
    final db = await _helper.database;
    await db.update('raw_materials', m.toMap(),
        where: 'id = ?', whereArgs: [m.id]);
  }

  /// Mengembalikan false jika bahan sudah dipakai di pembelian.
  Future<bool> delete(int id) async {
    final db = await _helper.database;
    final used = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM purchase_items WHERE raw_material_id = ?',
            [id])) ??
        0;
    if (used > 0) return false;
    await db.delete('raw_materials', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  /// Kurangi stok karena bahan dipakai.
  Future<void> useStock(int id, double quantity) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      final rows = await txn.query('raw_materials',
          columns: ['stock'], where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) throw ArgumentError('Bahan tidak ditemukan');
      final current = (rows.first['stock'] as num).toDouble();
      final next = StockCalculator.afterUse(current, quantity);
      await txn.update(
        'raw_materials',
        {'stock': next, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
