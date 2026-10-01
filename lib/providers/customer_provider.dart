import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repo;
  CustomerProvider([CustomerRepository? repo])
      : _repo = repo ?? CustomerRepository();

  List<Customer> customers = [];
  String query = '';
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    customers = await _repo.search(query);
    loading = false;
    notifyListeners();
  }

  Future<void> search(String q) async {
    query = q;
    await load();
  }

  Future<void> save({
    Customer? existing,
    required String name,
    String? phone,
    String? address,
  }) async {
    final now = DateTime.now();
    final ph = (phone == null || phone.trim().isEmpty) ? null : phone.trim();
    final ad = (address == null || address.trim().isEmpty) ? null : address.trim();
    if (existing == null) {
      await _repo.insert(Customer(
        name: name.trim(),
        phone: ph,
        address: ad,
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      await _repo.update(existing.copyWith(
        name: name.trim(),
        phone: ph,
        address: ad,
        updatedAt: now,
      ));
    }
    await load();
  }

  Future<void> remove(Customer c) async {
    await _repo.delete(c.id!);
    await load();
  }
}
