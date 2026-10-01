class CustomerOrder {
  final int id;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final DateTime date;
  final String status;
  final String orderType;
  final int total;
  final String? address;
  final String? notes;

  const CustomerOrder({
    required this.id,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.date,
    required this.status,
    required this.orderType,
    required this.total,
    this.address,
    this.notes,
  });

  factory CustomerOrder.fromMap(Map<String, Object?> m) => CustomerOrder(
        id: m['id'] as int,
        customerId: m['customer_id'] as int?,
        customerName: m['customer_name'] as String?,
        customerPhone: m['customer_phone'] as String?,
        date: DateTime.parse(m['order_date'] as String),
        status: m['status'] as String,
        orderType: m['order_type'] as String,
        total: m['total'] as int,
        address: m['address'] as String?,
        notes: m['notes'] as String?,
      );
}

class OrderItem {
  final String productName;
  final int quantity;
  final int price;
  final int subtotal;

  const OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItem.fromMap(Map<String, Object?> m) => OrderItem(
        productName: m['product_name'] as String,
        quantity: m['quantity'] as int,
        price: m['price'] as int,
        subtotal: m['subtotal'] as int,
      );
}

class CustomerOrderCount {
  final int customerId;
  final String name;
  final int count;
  const CustomerOrderCount(this.customerId, this.name, this.count);
}

class OrderStats {
  final int totalOrders;
  final int totalCustomers;
  final int newCustomersThisMonth;
  final List<CustomerOrderCount> topCustomers;

  const OrderStats({
    this.totalOrders = 0,
    this.totalCustomers = 0,
    this.newCustomersThisMonth = 0,
    this.topCustomers = const [],
  });
}
