import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repo;
  ProductProvider([ProductRepository? repo]) : _repo = repo ?? ProductRepository();

  List<Product> products = [];
  Map<int, int> sold = {};
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    products = await _repo.getAll();
    sold = await _repo.soldQuantities();
    loading = false;
    notifyListeners();
  }

  Future<void> save({
    Product? existing,
    required String name,
    required String category,
    required int sellingPrice,
    required int costPrice,
  }) async {
    final now = DateTime.now();
    if (existing == null) {
      await _repo.insert(Product(
        name: name,
        category: category,
        sellingPrice: sellingPrice,
        costPrice: costPrice,
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      await _repo.update(existing.copyWith(
        name: name,
        category: category,
        sellingPrice: sellingPrice,
        costPrice: costPrice,
        updatedAt: now,
      ));
    }
    await load();
  }

  Future<void> setActive(Product p, bool active) async {
    await _repo.setActive(p.id!, active);
    await load();
  }
}
