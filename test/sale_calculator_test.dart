import 'package:bakso_mie_ayam/core/utils/sale_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaleCalculator', () {
    const bakso = LineItem(price: 13000, cost: 7000, quantity: 2);
    const mie = LineItem(price: 12000, cost: 6000, quantity: 1);

    test('subtotal = harga x qty', () {
      expect(bakso.subtotal, 26000);
    });

    test('HPP = HPP produk x qty', () {
      expect(bakso.costTotal, 14000);
    });

    test('laba = omzet - HPP (contoh spesifikasi)', () {
      expect(bakso.profit, 12000);
    });

    test('contoh transaksi Budi: total 38.000, HPP 20.000, laba 18.000', () {
      final items = [bakso, mie];
      expect(SaleCalculator.total(items), 38000);
      expect(SaleCalculator.totalCost(items), 20000);
      expect(SaleCalculator.profit(items), 18000);
      expect(SaleCalculator.label(SaleCalculator.profit(items)), 'Laba');
    });

    test('diskon mengurangi total dan laba', () {
      final items = [bakso, mie];
      expect(SaleCalculator.total(items, discount: 3000), 35000);
      expect(SaleCalculator.profit(items, discount: 3000), 15000);
    });

    test('rugi jika HPP lebih besar dari penjualan', () {
      const item = LineItem(price: 10000, cost: 12000, quantity: 3);
      expect(SaleCalculator.profit([item]), -6000);
      expect(SaleCalculator.isLoss([item]), isTrue);
      expect(SaleCalculator.label(-6000), 'Rugi');
    });

    test('laba kotor dan laba bersih', () {
      expect(SaleCalculator.grossProfit(revenue: 500000, cogs: 300000), 200000);
      expect(
        SaleCalculator.netProfit(
            revenue: 500000, cogs: 300000, operationalCost: 50000),
        150000,
      );
    });

    test('ringkasan harian (agregasi beberapa transaksi)', () {
      final day = <List<LineItem>>[
        [bakso, mie],
        [const LineItem(price: 20000, cost: 11000, quantity: 1)],
      ];
      final revenue =
          day.fold<int>(0, (s, t) => s + SaleCalculator.total(t));
      final cogs =
          day.fold<int>(0, (s, t) => s + SaleCalculator.totalCost(t));
      expect(revenue, 58000);
      expect(cogs, 31000);
      expect(SaleCalculator.grossProfit(revenue: revenue, cogs: cogs), 27000);
    });

    test('ringkasan bulanan (agregasi hari)', () {
      const dailyRevenue = [58000, 42000, 60000];
      const dailyCogs = [31000, 22000, 33000];
      final rev = dailyRevenue.reduce((a, b) => a + b);
      final cogs = dailyCogs.reduce((a, b) => a + b);
      expect(
        SaleCalculator.netProfit(
            revenue: rev, cogs: cogs, operationalCost: 20000),
        54000,
      );
    });
  });
}
