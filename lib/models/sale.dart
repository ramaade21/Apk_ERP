import '../core/utils/sale_calculator.dart';

/// Baris item saat membuat transaksi.
class SaleLine {
  final int productId;
  final String productName;
  final LineItem item;

  const SaleLine({
    required this.productId,
    required this.productName,
    required this.item,
  });
}

class Sale {
  final int id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final DateTime date;
  final String orderType;
  final int subtotal;
  final int discount;
  final int total;
  final int totalCost;
  final int profit;
  final String? notes;

  const Sale({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.date,
    required this.orderType,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.totalCost,
    required this.profit,
    this.notes,
  });

  bool get isLoss => profit < 0;

  factory Sale.fromMap(Map<String, Object?> m) => Sale(
        id: m['id'] as int,
        invoiceNumber: m['invoice_number'] as String,
        customerId: m['customer_id'] as int?,
        customerName: m['customer_name'] as String?,
        date: DateTime.parse(m['transaction_date'] as String),
        orderType: m['order_type'] as String,
        subtotal: m['subtotal'] as int,
        discount: m['discount'] as int,
        total: m['total'] as int,
        totalCost: m['total_cost'] as int,
        profit: m['profit'] as int,
        notes: m['notes'] as String?,
      );
}

class SaleItem {
  final String productName;
  final int quantity;
  final int price;
  final int costPrice;
  final int subtotal;
  final int costTotal;
  final int profit;

  const SaleItem({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.costPrice,
    required this.subtotal,
    required this.costTotal,
    required this.profit,
  });

  factory SaleItem.fromMap(Map<String, Object?> m) => SaleItem(
        productName: m['product_name'] as String,
        quantity: m['quantity'] as int,
        price: m['price'] as int,
        costPrice: m['cost_price'] as int,
        subtotal: m['subtotal'] as int,
        costTotal: m['cost_total'] as int,
        profit: m['profit'] as int,
      );
}
