import '../core/database/database_helper.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final DatabaseHelper _helper;
  ExpenseRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  Future<List<Expense>> list({String query = '', DateTime? date}) async {
    final db = await _helper.database;
    final where = <String>[];
    final args = <Object?>[];
    final q = query.trim();
    if (q.isNotEmpty) {
      where.add('(name LIKE ? OR category LIKE ?)');
      args
        ..add('%$q%')
        ..add('%$q%');
    }
    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day + 1);
      where.add('expense_date >= ? AND expense_date < ?');
      args
        ..add(start.toIso8601String())
        ..add(end.toIso8601String());
    }
    final rows = await db.query(
      'expenses',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'expense_date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insert({
    required String category,
    required String name,
    required int amount,
    required DateTime date,
    String? notes,
  }) async {
    if (amount < 0) throw ArgumentError('Nominal tidak boleh negatif');
    final db = await _helper.database;
    return db.insert('expenses', {
      'category': category,
      'name': name,
      'amount': amount,
      'expense_date': date.toIso8601String(),
      'notes': notes,
    });
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
