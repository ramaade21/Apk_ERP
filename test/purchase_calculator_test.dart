import 'package:bakso_mie_ayam/core/utils/formatters.dart';
import 'package:bakso_mie_ayam/core/utils/purchase_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchaseCalculator', () {
    test('10 Kg x Rp120.000 = Rp1.200.000 (contoh spesifikasi)', () {
      expect(PurchaseCalculator.lineSubtotal(10, 120000), 1200000);
    });

    test('jumlah desimal dibulatkan ke Rupiah', () {
      expect(PurchaseCalculator.lineSubtotal(2.5, 15000), 37500);
      expect(PurchaseCalculator.lineSubtotal(0.333, 1000), 333);
    });

    test('total pembelian dari beberapa baris', () {
      expect(PurchaseCalculator.total([1200000, 37500, 62500]), 1300000);
    });
  });

  group('StockCalculator', () {
    test('stok bertambah saat pembelian', () {
      expect(StockCalculator.afterPurchase(2, 10), 12);
    });

    test('stok berkurang saat dipakai', () {
      expect(StockCalculator.afterUse(12, 4.5), 7.5);
    });

    test('pemakaian melebihi stok ditolak', () {
      expect(() => StockCalculator.afterUse(3, 5), throwsArgumentError);
    });

    test('pemakaian 0 atau negatif ditolak', () {
      expect(() => StockCalculator.afterUse(3, 0), throwsArgumentError);
      expect(() => StockCalculator.afterUse(3, -1), throwsArgumentError);
    });

    test('stok menipis jika stok <= minimum', () {
      expect(StockCalculator.isLow(2, 2), isTrue);
      expect(StockCalculator.isLow(1, 2), isTrue);
      expect(StockCalculator.isLow(3, 2), isFalse);
    });
  });

  group('Fmt.qty', () {
    test('menghilangkan nol berlebih', () {
      expect(Fmt.qty(10.0), '10');
      expect(Fmt.qty(2.5), '2.5');
      expect(Fmt.qty(0.1 + 0.2), '0.3');
    });
  });
}
