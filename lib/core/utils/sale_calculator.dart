/// Satu baris item penjualan (semua nominal dalam Rupiah bulat).
class LineItem {
  final int price;
  final int cost;
  final int quantity;

  const LineItem({
    required this.price,
    required this.cost,
    required this.quantity,
  });

  int get subtotal => price * quantity;
  int get costTotal => cost * quantity;
  int get profit => subtotal - costTotal;
}

/// Perhitungan penjualan, HPP, dan laba/rugi.
class SaleCalculator {
  static int subtotal(List<LineItem> items) =>
      items.fold(0, (sum, i) => sum + i.subtotal);

  static int totalCost(List<LineItem> items) =>
      items.fold(0, (sum, i) => sum + i.costTotal);

  /// Total penjualan = subtotal - diskon.
  static int total(List<LineItem> items, {int discount = 0}) =>
      subtotal(items) - discount;

  /// Laba/rugi = total penjualan - total HPP.
  static int profit(List<LineItem> items, {int discount = 0}) =>
      total(items, discount: discount) - totalCost(items);

  static bool isLoss(List<LineItem> items, {int discount = 0}) =>
      profit(items, discount: discount) < 0;

  static int grossProfit({required int revenue, required int cogs}) =>
      revenue - cogs;

  /// Laba bersih = omzet - HPP - biaya operasional.
  static int netProfit({
    required int revenue,
    required int cogs,
    required int operationalCost,
  }) =>
      revenue - cogs - operationalCost;

  static String label(int profit) => profit < 0 ? 'Rugi' : 'Laba';
}
