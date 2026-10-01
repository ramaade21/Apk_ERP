import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/helpers/ui_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: provider.loading && provider.products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              itemCount: provider.products.length,
              itemBuilder: (context, i) {
                final p = provider.products[i];
                final sold = provider.sold[p.id] ?? 0;
                return Card(
                  child: ListTile(
                    onTap: () => _openForm(context, existing: p),
                    title: Text(
                      p.name,
                      style: TextStyle(
                        decoration:
                            p.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(
                      '${p.category} • Jual ${Fmt.rupiah(p.sellingPrice)} • '
                      'HPP ${Fmt.rupiah(p.costPrice)}\n'
                      'Margin ${Fmt.rupiah(p.marginPerPortion)} • Terjual $sold porsi',
                    ),
                    isThreeLine: true,
                    trailing: Switch(
                      value: p.isActive,
                      onChanged: (v) =>
                          context.read<ProductProvider>().setActive(p, v),
                    ),
                    leading: Icon(
                      Icons.ramen_dining,
                      color: p.marginPerPortion < 0
                          ? AppTheme.lossColor
                          : AppTheme.profitColor,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openForm(BuildContext context, {Product? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProductForm(existing: existing),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final Product? existing;
  const _ProductForm({this.existing});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  late String _category;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(text: e?.sellingPrice.toString() ?? '');
    _cost = TextEditingController(text: e?.costPrice.toString() ?? '');
    _category = e?.category ?? AppConstants.productCategories.first;
    if (!AppConstants.productCategories.contains(_category)) {
      _category = AppConstants.productCategories.first;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _cost.dispose();
    super.dispose();
  }

  String? _validateMoney(String? v) {
    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Harus berupa angka';
    if (n < 0) return 'Tidak boleh negatif';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProductProvider>();
    final navigator = Navigator.of(context);
    try {
      await provider.save(
        existing: widget.existing,
        name: _name.text.trim(),
        category: _category,
        sellingPrice: int.parse(_price.text.trim()),
        costPrice: int.parse(_cost.text.trim()),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Gagal menyimpan produk: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Tambah Produk' : 'Edit Produk',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama produk'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama produk wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final c in AppConstants.productCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Harga jual', prefixText: 'Rp '),
                validator: _validateMoney,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cost,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'HPP / modal per porsi', prefixText: 'Rp '),
                validator: _validateMoney,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _submit, child: const Text('Simpan')),
            ],
          ),
        ),
      ),
    );
  }
}
