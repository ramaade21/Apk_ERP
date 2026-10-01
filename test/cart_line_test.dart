import 'package:bakso_mie_ayam/models/product.dart';
import 'package:bakso_mie_ayam/widgets/cart_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final product = Product(
    id: 1,
    name: 'Bakso Isi Daging',
    category: 'Bakso',
    sellingPrice: 13000,
    costPrice: 7000,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  group('CartLine', () {
    test('harga awal mengikuti harga produk', () {
      final line = CartLine(product, quantity: 2);
      expect(line.price, 13000);
      expect(line.priceChanged, isFalse);
      expect(line.item.subtotal, 26000);
      expect(line.item.profit, 12000);
    });

    test('harga bisa diubah tanpa mengubah HPP maupun harga master', () {
      final line = CartLine(product, quantity: 2, price: 15000);
      expect(line.priceChanged, isTrue);
      expect(line.item.subtotal, 30000);
      expect(line.item.costTotal, 14000);
      expect(line.item.profit, 16000);
      expect(product.sellingPrice, 13000);
    });

    test('harga di bawah HPP menghasilkan rugi', () {
      final line = CartLine(product, quantity: 1, price: 6000);
      expect(line.item.profit, -1000);
    });
  });
}
