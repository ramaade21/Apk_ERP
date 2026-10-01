class Expense {
  final int id;
  final String category;
  final String name;
  final int amount;
  final DateTime date;
  final String? notes;

  const Expense({
    required this.id,
    required this.category,
    required this.name,
    required this.amount,
    required this.date,
    this.notes,
  });

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int,
        category: m['category'] as String,
        name: m['name'] as String,
        amount: m['amount'] as int,
        date: DateTime.parse(m['expense_date'] as String),
        notes: m['notes'] as String?,
      );
}
