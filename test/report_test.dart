import 'package:bakso_mie_ayam/core/utils/report_periods.dart';
import 'package:bakso_mie_ayam/models/report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DaySummary', () {
    test('laba kotor = omzet - HPP; laba bersih = laba kotor - operasional', () {
      final d = DaySummary(
        date: DateTime(2026, 9, 29),
        revenue: 500000,
        cogs: 300000,
        purchases: 400000,
        operational: 50000,
        transactions: 12,
      );
      expect(d.grossProfit, 200000);
      expect(d.netProfit, 150000);
      expect(d.totalExpense, 450000);
    });

    test('pembelian bahan baku tidak mengurangi laba bersih (sudah di HPP)', () {
      final a = DaySummary(
          date: DateTime(2026, 9, 29), revenue: 100000, cogs: 60000);
      final b = DaySummary(
          date: DateTime(2026, 9, 29),
          revenue: 100000,
          cogs: 60000,
          purchases: 999999);
      expect(a.netProfit, b.netProfit);
    });
  });

  group('PeriodSummary (laporan harian)', () {
    test('contoh spesifikasi: 2 x Bakso 13.000 (HPP 7.000) = laba 12.000', () {
      final day = DaySummary(
        date: DateTime(2026, 9, 29),
        revenue: 26000,
        cogs: 14000,
        transactions: 1,
      );
      final s = PeriodSummary.fromDays([day], customers: 1);
      expect(s.revenue, 26000);
      expect(s.cogs, 14000);
      expect(s.grossProfit, 12000);
      expect(s.netProfit, 12000);
      expect(s.isLoss, isFalse);
      expect(s.customers, 1);
    });

    test('rugi jika biaya operasional melebihi laba kotor', () {
      final day = DaySummary(
        date: DateTime(2026, 9, 29),
        revenue: 100000,
        cogs: 60000,
        operational: 70000,
      );
      final s = PeriodSummary.fromDays([day]);
      expect(s.netProfit, -30000);
      expect(s.isLoss, isTrue);
    });

    test('hari kosong menghasilkan nol', () {
      final s = PeriodSummary.fromDays([DaySummary(date: DateTime(2026, 9, 1))]);
      expect(s.revenue, 0);
      expect(s.netProfit, 0);
      expect(s.transactions, 0);
    });
  });

  group('PeriodSummary (laporan bulanan)', () {
    test('menjumlahkan seluruh hari dalam bulan', () {
      final days = [
        DaySummary(
            date: DateTime(2026, 9, 1),
            revenue: 58000,
            cogs: 31000,
            operational: 5000,
            transactions: 3),
        DaySummary(
            date: DateTime(2026, 9, 2),
            revenue: 42000,
            cogs: 22000,
            purchases: 300000,
            transactions: 2),
        DaySummary(date: DateTime(2026, 9, 3)),
      ];
      final s = PeriodSummary.fromDays(days, customers: 4);
      expect(s.revenue, 100000);
      expect(s.cogs, 53000);
      expect(s.purchases, 300000);
      expect(s.operational, 5000);
      expect(s.grossProfit, 47000);
      expect(s.netProfit, 42000);
      expect(s.transactions, 5);
      expect(s.customers, 4);
    });
  });

  group('ReportPeriods', () {
    test('rentang satu hari', () {
      final r = ReportPeriods.day(DateTime(2026, 9, 29, 15, 30));
      expect(r.start, DateTime(2026, 9, 29));
      expect(r.end, DateTime(2026, 9, 30));
      expect(r.dates.length, 1);
    });

    test('September 2026 memiliki 30 hari', () {
      final r = ReportPeriods.month(2026, 9);
      expect(r.dates.length, 30);
      expect(r.dates.first, DateTime(2026, 9, 1));
      expect(r.dates.last, DateTime(2026, 9, 30));
    });

    test('Februari tahun kabisat 29 hari, non-kabisat 28 hari', () {
      expect(ReportPeriods.month(2028, 2).dates.length, 29);
      expect(ReportPeriods.month(2026, 2).dates.length, 28);
    });

    test('Desember berakhir di 1 Januari tahun berikutnya', () {
      final r = ReportPeriods.month(2026, 12);
      expect(r.end, DateTime(2027, 1, 1));
      expect(r.dates.length, 31);
    });

    test('7 hari terakhir termasuk hari ini', () {
      final r = ReportPeriods.lastDays(7, DateTime(2026, 9, 29));
      expect(r.dates.length, 7);
      expect(r.dates.first, DateTime(2026, 9, 23));
      expect(r.dates.last, DateTime(2026, 9, 29));
    });
  });
}
