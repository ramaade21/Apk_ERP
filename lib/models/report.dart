/// Ringkasan satu hari.
class DaySummary {
  final DateTime date;
  final int revenue;
  final int cogs;
  final int purchases;
  final int operational;
  final int transactions;

  const DaySummary({
    required this.date,
    this.revenue = 0,
    this.cogs = 0,
    this.purchases = 0,
    this.operational = 0,
    this.transactions = 0,
  });

  int get grossProfit => revenue - cogs;

  /// Laba bersih = omzet - HPP - biaya operasional.
  int get netProfit => revenue - cogs - operational;

  /// Pengeluaran kas = pembelian bahan baku + biaya operasional.
  int get totalExpense => purchases + operational;
}

/// Ringkasan periode (hari/bulan).
class PeriodSummary {
  final int revenue;
  final int cogs;
  final int purchases;
  final int operational;
  final int transactions;
  final int customers;

  const PeriodSummary({
    this.revenue = 0,
    this.cogs = 0,
    this.purchases = 0,
    this.operational = 0,
    this.transactions = 0,
    this.customers = 0,
  });

  int get grossProfit => revenue - cogs;
  int get netProfit => revenue - cogs - operational;
  int get totalExpense => purchases + operational;
  bool get isLoss => netProfit < 0;

  factory PeriodSummary.fromDays(List<DaySummary> days, {int customers = 0}) {
    return PeriodSummary(
      revenue: days.fold(0, (s, d) => s + d.revenue),
      cogs: days.fold(0, (s, d) => s + d.cogs),
      purchases: days.fold(0, (s, d) => s + d.purchases),
      operational: days.fold(0, (s, d) => s + d.operational),
      transactions: days.fold(0, (s, d) => s + d.transactions),
      customers: customers,
    );
  }
}

class ProductSales {
  final String name;
  final int quantity;
  final int revenue;
  final int cost;

  const ProductSales({
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.cost,
  });

  int get profit => revenue - cost;
}
