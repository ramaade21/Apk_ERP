import 'package:bakso_mie_ayam/core/utils/csv.dart';
import 'package:bakso_mie_ayam/core/utils/receipt_builder.dart';
import 'package:bakso_mie_ayam/models/sale.dart';
import 'package:bakso_mie_ayam/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Csv', () {
    test('sel biasa dan angka', () {
      expect(Csv.cell('Bakso'), 'Bakso');
      expect(Csv.cell(13000), '13000');
      expect(Csv.cell(null), '');
    });

    test('koma, petik, dan baris baru di-escape', () {
      expect(Csv.cell('Jl. Mawar, No. 10'), '"Jl. Mawar, No. 10"');
      expect(Csv.cell('Dia bilang "enak"'), '"Dia bilang ""enak"""');
      expect(Csv.cell('a\nb'), '"a\nb"');
    });

    test('teks berawalan rumus diberi petik (anti CSV injection)', () {
      expect(Csv.cell('=1+1'), "'=1+1");
      expect(Csv.cell('@SUM(A1)'), "'@SUM(A1)");
      expect(Csv.cell('-cmd'), "'-cmd");
    });

    test('angka negatif tetap angka', () {
      expect(Csv.cell(-6000), '-6000');
    });

    test('encode beberapa baris', () {
      expect(
        Csv.encode([
          ['Produk', 'Qty'],
          ['Mie Ayam', 2],
        ]),
        'Produk,Qty\r\nMie Ayam,2',
      );
    });
  });

  group('ReceiptBuilder', () {
    final sale = Sale(
      id: 1,
      invoiceNumber: 'INV-20260929-001',
      customerName: 'Budi',
      date: DateTime(2026, 9, 29, 12, 30),
      orderType: 'Delivery',
      subtotal: 38000,
      discount: 3000,
      total: 35000,
      totalCost: 20000,
      profit: 15000,
    );
    const items = [
      SaleItem(
        productName: 'Bakso Isi Daging',
        quantity: 2,
        price: 13000,
        costPrice: 7000,
        subtotal: 26000,
        costTotal: 14000,
        profit: 12000,
      ),
      SaleItem(
        productName: 'Mie Ayam',
        quantity: 1,
        price: 12000,
        costPrice: 6000,
        subtotal: 12000,
        costTotal: 6000,
        profit: 6000,
      ),
    ];

    test('memuat nomor, customer, item, dan total', () {
      final text = ReceiptBuilder.build(sale, items);
      expect(text, contains('INV-20260929-001'));
      expect(text, contains('Budi'));
      expect(text, contains('Bakso Isi Daging x2'));
      expect(text, contains('Mie Ayam x1'));
      expect(text, contains('35.000'));
      expect(text, contains('29/09/2026 12:30'));
    });

    test('tidak membocorkan HPP maupun laba', () {
      final text = ReceiptBuilder.build(sale, items).toLowerCase();
      expect(text.contains('hpp'), isFalse);
      expect(text.contains('laba'), isFalse);
      expect(text.contains('rugi'), isFalse);
    });
  });

  test('nama file backup memakai stempel waktu', () {
    expect(
      BackupService.backupFileName(DateTime(2026, 9, 29, 8, 5, 3)),
      'backup-bakso-mie-ayam-20260929-080503.db',
    );
  });
}
