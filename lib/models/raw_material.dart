import '../core/utils/purchase_calculator.dart';

class RawMaterial {
  final int? id;
  final String name;
  final String? category;
  final String unit;
  final double stock;
  final double minimumStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RawMaterial({
    this.id,
    required this.name,
    this.category,
    required this.unit,
    required this.stock,
    required this.minimumStock,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLow => StockCalculator.isLow(stock, minimumStock);

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'unit': unit,
        'stock': stock,
        'minimum_stock': minimumStock,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory RawMaterial.fromMap(Map<String, Object?> m) => RawMaterial(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String?,
        unit: m['unit'] as String,
        stock: (m['stock'] as num).toDouble(),
        minimumStock: (m['minimum_stock'] as num).toDouble(),
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
