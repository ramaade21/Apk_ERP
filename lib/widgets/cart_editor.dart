import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../core/utils/sale_calculator.dart';
import '../models/product.dart';

/// Satu baris keranjang (produk + jumlah + harga jual).
/// Harga awal mengikuti harga produk, tetapi bisa diubah per transaksi
/// tanpa mengubah harga master produk.
class CartLine {
  final Product product;
  int quantity;
  int price;

  CartLine(this.product, {this.quantity = 1, int? price})
      : price = price ?? product.sellingPrice;

  bool get priceChanged => price != product.sellingPrice;

  LineItem get item => LineItem(
        price: price,
        cost: product.costPrice,
        quantity: quantity,
      );
}

class _LineValues {
  final int price;
  final int quantity;
  const _LineValues(this.price, this.quantity);
}

/// Editor daftar produk + jumlah + harga. List [lines] dimodifikasi langsung,
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

  Future<_LineValues?> _askValues(
    BuildContext context,
    Product product, {
    int? price,
    int? quantity,
  }) {
    return showDialog<_LineValues>(
      context: context,
      builder: (_) => _LineDialog(
        product: product,
        initialPrice: price ?? product.sellingPrice,
        initialQuantity: quantity ?? 1,
      ),
    );
  }

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
    if (picked == null || !context.mounted) return;

    final values = await _askValues(context, picked);
    if (values == null) return;

    // Produk yang sama dengan harga yang sama digabung; harga berbeda = baris baru.
    final idx = lines.indexWhere(
        (l) => l.product.id == picked.id && l.price == values.price);
    if (idx >= 0) {
      lines[idx].quantity += values.quantity;
    } else {
      lines.add(CartLine(picked,
          quantity: values.quantity, price: values.price));
    }
    onChanged();
  }

  Future<void> _editLine(BuildContext context, CartLine line) async {
    final values = await _askValues(
      context,
      line.product,
      price: line.price,
      quantity: line.quantity,
    );
    if (values == null) return;
    line.price = values.price;
    line.quantity = values.quantity;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _editLine(context, line),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(line.product.name)),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_outlined, size: 14),
                            ],
                          ),
                          Text(
                            '${Fmt.rupiah(line.price)} x ${line.quantity}'
                            ' = ${Fmt.rupiah(line.item.subtotal)}'
                            '${line.priceChanged ? ' (harga diubah)' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: line.priceChanged
                                  ? theme.colorScheme.tertiary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _LineDialog extends StatefulWidget {
  final Product product;
  final int initialPrice;
  final int initialQuantity;

  const _LineDialog({
    required this.product,
    required this.initialPrice,
    required this.initialQuantity,
  });

  @override
  State<_LineDialog> createState() => _LineDialogState();
}

class _LineDialogState extends State<_LineDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _price =
      TextEditingController(text: widget.initialPrice.toString());
  late final TextEditingController _qty =
      TextEditingController(text: widget.initialQuantity.toString());

  @override
  void dispose() {
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _LineValues(int.parse(_price.text.trim()), int.parse(_qty.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return AlertDialog(
      title: Text(p.name),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Harga jual',
                  prefixText: 'Rp ',
                  helperText: 'Harga normal ${Fmt.rupiah(p.sellingPrice)} • '
                      'HPP ${Fmt.rupiah(p.costPrice)}',
                  helperMaxLines: 2,
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Harga wajib berupa angka';
                  if (n < 0) return 'Harga tidak boleh negatif';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah'),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Jumlah wajib berupa angka';
                  if (n <= 0) return 'Jumlah harus lebih dari 0';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
