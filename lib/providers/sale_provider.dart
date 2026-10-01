import 'package:flutter/foundation.dart';

import '../models/sale.dart';
import '../repositories/sale_repository.dart';

class SaleProvider extends ChangeNotifier {
  final SaleRepository _repo;
  SaleProvider([SaleRepository? repo]) : _repo = repo ?? SaleRepository();

  List<Sale> sales = [];
  String query = '';
  DateTime? dateFilter;
  bool loading = false;

  int get totalRevenue => sales.fold(0, (s, e) => s + e.total);
  int get totalProfit => sales.fold(0, (s, e) => s + e.profit);

  Future<void> load() async {
    loading = true;
    notifyListeners();
    sales = await _repo.list(query: query, date: dateFilter);
    loading = false;
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

  Future<int> create({
    int? customerId,
    required DateTime date,
    required String orderType,
    required List<SaleLine> lines,
    int discount = 0,
    String? notes,
  }) async {
    final id = await _repo.create(
      customerId: customerId,
      date: date,
      orderType: orderType,
      lines: lines,
      discount: discount,
      notes: notes,
    );
    await load();
    return id;
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load();
  }
}
