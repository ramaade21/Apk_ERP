import 'package:flutter/foundation.dart';

import '../models/customer_order.dart';
import '../models/sale.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repo;
  OrderProvider([OrderRepository? repo]) : _repo = repo ?? OrderRepository();

  List<CustomerOrder> orders = [];
  OrderStats stats = const OrderStats();
  String query = '';
  String? statusFilter;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    orders = await _repo.list(query: query, status: statusFilter);
    stats = await _repo.stats();
    loading = false;
    notifyListeners();
  }

  Future<void> setQuery(String q) async {
    query = q;
    await load();
  }

  Future<void> setStatus(String? s) async {
    statusFilter = s;
    await load();
  }

  Future<int> create({
    required int customerId,
    required DateTime date,
    required String orderType,
    required String status,
    required List<SaleLine> lines,
    String? address,
    String? notes,
  }) async {
    final id = await _repo.create(
      customerId: customerId,
      date: date,
      orderType: orderType,
      status: status,
      lines: lines,
      address: address,
      notes: notes,
    );
    await load();
    return id;
  }

  Future<void> updateStatus(int id, String status) async {
    await _repo.updateStatus(id, status);
    await load();
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load();
  }

  Future<List<OrderItem>> items(int orderId) => _repo.items(orderId);
}
