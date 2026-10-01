import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../core/utils/sale_calculator.dart';
import '../models/product.dart';

/// Satu baris keranjang (produk + jumlah).
class CartLine {
  final Product product;
  int quantity;

  CartLine(this.product, [this.quantity = 1]);

  LineItem get item => LineItem(
        price: product.sellingPrice,
        cost: product.costPrice,
        quantity: quantity,
      );
}

/// Editor daftar produk + jumlah. List [lines] dimodifikasi langsung,
/// lalu [onChanged] dipanggil agar parent memanggil setState.
class CartEditor extends StatelessWidget {
  final List<CartLine> lines;
  final List<Product> products;
  final VoidCallback onChanged;

  const CartEditor({
    super.key,
    required this.lines,
    required this.products,
    required this.onChanged,
  });

  Future<void> _addProduct(BuildContext context) async {
    final picked = await showDialog<Product>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih produk'),
        children: [
          for (final p in products)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Text('${p.name} • ${Fmt.rupiah(p.sellingPrice)}'),
            ),
        ],
      ),
    );
    if (picked == null) return;
    final idx = lines.indexWhere((l) => l.product.id == picked.id);
    if (idx >= 0) {
      lines[idx].quantity++;
    } else {
      lines.add(CartLine(picked));
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.product.name),
                      Text(
                        '${Fmt.rupiah(line.product.sellingPrice)} x ${line.quantity}'
                        ' = ${Fmt.rupiah(line.item.subtotal)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Kurangi',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (line.quantity > 1) {
                      line.quantity--;
                    } else {
                      lines.remove(line);
                    }
                    onChanged();
                  },
                ),
                Text('${line.quantity}'),
                IconButton(
                  tooltip: 'Tambah',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    line.quantity++;
                    onChanged();
                  },
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: products.isEmpty ? null : () => _addProduct(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah produk'),
        ),
      ],
    );
  }
}
