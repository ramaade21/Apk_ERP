import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repo;
  ExpenseProvider([ExpenseRepository? repo])
      : _repo = repo ?? ExpenseRepository();

  List<Expense> expenses = [];
  String query = '';
  DateTime? dateFilter;

  int get total => expenses.fold(0, (s, e) => s + e.amount);

  Future<void> load() async {
    expenses = await _repo.list(query: query, date: dateFilter);
    notifyListeners();
  }

  Future<void> setQuery(String q) async {
    query = q;
    await load();
  }

  Future<void> setDate(DateTime? d) async {
    dateFilter = d;
    await load();
  }

  Future<void> add({
    required String category,
    required String name,
    required int amount,
    required DateTime date,
    String? notes,
  }) async {
    await _repo.insert(
        category: category,
        name: name,
        amount: amount,
        date: date,
        notes: notes);
    await load();
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load();
  }
}
