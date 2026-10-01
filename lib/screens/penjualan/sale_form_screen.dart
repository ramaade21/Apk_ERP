import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/helpers/ui_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/sale_calculator.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../providers/sale_provider.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/cart_editor.dart';

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key});

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _discount = TextEditingController(text: '0');
  final _address = TextEditingController();
  final _notes = TextEditingController();
  final _lines = <CartLine>[];

  List<Customer> _customers = [];
  List<Product> _products = [];
  int? _customerId;
  String _orderType = AppConstants.orderTypes.first;
  DateTime _dateTime = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _discount.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final customers = await CustomerRepository().search();
    final products = await ProductRepository().getAll(includeInactive: false);
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _products = products;
    });
  }

  int get _discountValue => int.tryParse(_discount.text.trim()) ?? 0;
  List<LineItem> get _items => _lines.map((l) => l.item).toList();
  bool get _isDelivery => _orderType == 'Delivery';

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => _dateTime = DateTime(
        d.year, d.month, d.day, _dateTime.hour, _dateTime.minute));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (t == null) return;
    setState(() => _dateTime = DateTime(
        _dateTime.year, _dateTime.month, _dateTime.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      showMessage(context, 'Tambahkan minimal satu produk', error: true);
      return;
    }
    final provider = context.read<SaleProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notes = [
      if (_isDelivery) 'Alamat: ${_address.text.trim()}',
      if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
    ].join('\n');

    setState(() => _saving = true);
    try {
      await provider.create(
        customerId: _customerId,
        date: _dateTime,
        orderType: _orderType,
        discount: _discountValue,
        notes: notes.isEmpty ? null : notes,
        lines: [
          for (final l in _lines)
            SaleLine(
              productId: l.product.id!,
              productName: l.product.name,
              item: l.item,
            ),
        ],
      );
      navigator.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil disimpan')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Gagal menyimpan transaksi: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final discount = _discountValue;
    final subtotal = SaleCalculator.subtotal(items);
    final total = SaleCalculator.total(items, discount: discount);
    final cost = SaleCalculator.totalCost(items);
    final profit = SaleCalculator.profit(items, discount: discount);
    final color = profit < 0 ? AppTheme.lossColor : AppTheme.profitColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(Fmt.date(_dateTime)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(Fmt.time(_dateTime)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _customerId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Customer'),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('Umum (tanpa customer)')),
                for (final c in _customers)
                  DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) {
                setState(() => _customerId = v);
                final matches = _customers.where((c) => c.id == v);
                if (matches.isNotEmpty &&
                    _address.text.trim().isEmpty &&
                    matches.first.address != null) {
                  _address.text = matches.first.address!;
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _orderType,
              decoration: const InputDecoration(labelText: 'Jenis pesanan'),
              items: [
                for (final t in AppConstants.orderTypes)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _orderType = v ?? _orderType),
            ),
            if (_isDelivery) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Alamat pengantaran'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Alamat wajib diisi untuk delivery'
                    : null,
              ),
            ],
            const SizedBox(height: 20),
            Text('Produk', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            CartEditor(
              lines: _lines,
              products: _products,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discount,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Diskon', prefixText: 'Rp '),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v.trim());
                if (n == null) return 'Harus berupa angka';
                if (n < 0) return 'Tidak boleh negatif';
                if (n > subtotal) return 'Diskon melebihi subtotal';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _summary('Subtotal', Fmt.rupiah(subtotal)),
                    _summary('Diskon', Fmt.rupiah(discount)),
                    _summary('Total', Fmt.rupiah(total), bold: true),
                    _summary('Modal / HPP', Fmt.rupiah(cost)),
                    _summary(
                      profit < 0 ? 'RUGI' : 'Laba',
                      Fmt.rupiah(profit.abs()),
                      bold: true,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Transaksi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(String label, String value,
      {bool bold = false, Color? color}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : null, color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
