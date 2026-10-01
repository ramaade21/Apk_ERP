class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  Customer copyWith({
    String? name,
    String? phone,
    String? address,
    DateTime? updatedAt,
  }) =>
      Customer(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
