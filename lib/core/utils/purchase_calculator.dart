/// Perhitungan pembelian bahan baku dan stok.
class PurchaseCalculator {
  /// Subtotal = jumlah x harga satuan (dibulatkan ke Rupiah).
  static int lineSubtotal(double quantity, int price) =>
      (quantity * price).round();

  static int total(Iterable<int> subtotals) =>
      subtotals.fold(0, (a, b) => a + b);
}

class StockCalculator {
  static double afterPurchase(double stock, double quantity) => stock + quantity;

  /// Stok berkurang saat bahan dipakai. Tidak boleh melebihi stok.
  static double afterUse(double stock, double quantity) {
    if (quantity <= 0) {
      throw ArgumentError('Jumlah harus lebih dari 0');
    }
    if (quantity > stock) {
      throw ArgumentError('Stok tidak cukup');
    }
    return stock - quantity;
  }

  /// Stok menipis jika stok <= stok minimum.
  static bool isLow(double stock, double minimumStock) => stock <= minimumStock;
}
