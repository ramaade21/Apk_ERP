import '../core/utils/purchase_calculator.dart';

/// Baris bahan saat membuat pembelian.
class PurchaseLine {
  final int materialId;
  final String materialName;
  final String unit;
  final double quantity;
  final int price;

  const PurchaseLine({
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.quantity,
    required this.price,
  });

  int get subtotal => PurchaseCalculator.lineSubtotal(quantity, price);
}

class Purchase {
  final int id;
  final String purchaseNumber;
  final String? supplier;
  final DateTime date;
  final int total;
  final String? notes;

  const Purchase({
    required this.id,
    required this.purchaseNumber,
    this.supplier,
    required this.date,
    required this.total,
    this.notes,
  });

  factory Purchase.fromMap(Map<String, Object?> m) => Purchase(
        id: m['id'] as int,
        purchaseNumber: m['purchase_number'] as String,
        supplier: m['supplier'] as String?,
        date: DateTime.parse(m['purchase_date'] as String),
        total: m['total'] as int,
        notes: m['notes'] as String?,
      );
}

class PurchaseItem {
  final String materialName;
  final String unit;
  final double quantity;
  final int price;
  final int subtotal;

  const PurchaseItem({
    required this.materialName,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory PurchaseItem.fromMap(Map<String, Object?> m) => PurchaseItem(
        materialName: m['material_name'] as String,
        unit: m['unit'] as String,
        quantity: (m['quantity'] as num).toDouble(),
        price: m['price'] as int,
        subtotal: m['subtotal'] as int,
      );
}
