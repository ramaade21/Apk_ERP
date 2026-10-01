import 'package:flutter/foundation.dart';

import '../models/purchase.dart';
import '../repositories/purchase_repository.dart';

class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepository _repo;
  PurchaseProvider([PurchaseRepository? repo])
      : _repo = repo ?? PurchaseRepository();

  List<Purchase> purchases = [];
  String query = '';
  DateTime? dateFilter;

  int get totalSpent => purchases.fold(0, (s, p) => s + p.total);

  Future<void> load() async {
    purchases = await _repo.list(query: query, date: dateFilter);
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

  Future<void> create({
    String? supplier,
    required DateTime date,
    required List<PurchaseLine> lines,
    String? notes,
  }) async {
    await _repo.create(
        supplier: supplier, date: date, lines: lines, notes: notes);
    await load();
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load();
  }

  Future<List<PurchaseItem>> items(int id) => _repo.items(id);
}
