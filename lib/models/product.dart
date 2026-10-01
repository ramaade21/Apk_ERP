class Product {
  final int? id;
  final String name;
  final String category;
  final int sellingPrice;
  final int costPrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    this.id,
    required this.name,
    required this.category,
    required this.sellingPrice,
    required this.costPrice,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  int get marginPerPortion => sellingPrice - costPrice;

  Product copyWith({
    String? name,
    String? category,
    int? sellingPrice,
    int? costPrice,
    bool? isActive,
    DateTime? updatedAt,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        costPrice: costPrice ?? this.costPrice,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'selling_price': sellingPrice,
        'cost_price': costPrice,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String,
        sellingPrice: m['selling_price'] as int,
        costPrice: m['cost_price'] as int,
        isActive: (m['is_active'] as int) == 1,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
