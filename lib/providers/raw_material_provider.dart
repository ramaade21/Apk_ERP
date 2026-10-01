import 'package:flutter/foundation.dart';

import '../models/raw_material.dart';
import '../repositories/raw_material_repository.dart';

class RawMaterialProvider extends ChangeNotifier {
  final RawMaterialRepository _repo;
  RawMaterialProvider([RawMaterialRepository? repo])
      : _repo = repo ?? RawMaterialRepository();

  List<RawMaterial> materials = [];
  String query = '';

  List<RawMaterial> get lowStock => materials.where((m) => m.isLow).toList();

  Future<void> load() async {
    materials = await _repo.list(query);
    notifyListeners();
  }

  Future<void> search(String q) async {
    query = q;
    await load();
  }

  Future<void> save({
    RawMaterial? existing,
    required String name,
    required String category,
    required String unit,
    required double stock,
    required double minimumStock,
  }) async {
    final now = DateTime.now();
    if (existing == null) {
      await _repo.insert(RawMaterial(
        name: name,
        category: category,
        unit: unit,
        stock: stock,
        minimumStock: minimumStock,
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      await _repo.update(RawMaterial(
        id: existing.id,
        name: name,
        category: category,
        unit: unit,
        stock: existing.stock,
        minimumStock: minimumStock,
        createdAt: existing.createdAt,
        updatedAt: now,
      ));
    }
    await load();
  }

  Future<bool> remove(RawMaterial m) async {
    final ok = await _repo.delete(m.id!);
    await load();
    return ok;
  }

  Future<void> useStock(RawMaterial m, double quantity) async {
    await _repo.useStock(m.id!, quantity);
    await load();
  }
}
