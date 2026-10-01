import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/helpers/ui_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/sale_calculator.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../providers/order_provider.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/cart_editor.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  final _lines = <CartLine>[];

  List<Customer> _customers = [];
  List<Product> _products = [];
  int? _customerId;
  String _orderType = AppConstants.orderTypes.first;
  String _status = AppConstants.orderStatuses.first;
  DateTime _dateTime = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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
    final provider = context.read<OrderProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final address = _address.text.trim();
    final notes = _notes.text.trim();

    setState(() => _saving = true);
    try {
      await provider.create(
        customerId: _customerId!,
        date: _dateTime,
        orderType: _orderType,
        status: _status,
        address: address.isEmpty ? null : address,
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
          const SnackBar(content: Text('Pesanan berhasil disimpan')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Gagal menyimpan pesanan: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = SaleCalculator.subtotal(_lines.map((l) => l.item).toList());
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_customers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                    'Belum ada customer. Tambahkan dulu di Lainnya > Customer.'),
              ),
            DropdownButtonFormField<int>(
              initialValue: _customerId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Customer'),
              items: [
                for (final c in _customers)
                  DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
              ],
              validator: (v) => v == null ? 'Pilih customer' : null,
              onChanged: (v) {
                setState(() => _customerId = v);
                final matches = _customers.where((c) => c.id == v);
                if (matches.isNotEmpty && matches.first.address != null) {
                  _address.text = matches.first.address!;
                }
              },
            ),
            const SizedBox(height: 12),
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
            DropdownButtonFormField<String>(
              initialValue: _orderType,
              decoration: const InputDecoration(labelText: 'Jenis pesanan'),
              items: [
                for (final t in AppConstants.orderTypes)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _orderType = v ?? _orderType),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final s in AppConstants.orderStatuses)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: InputDecoration(
                labelText:
                    _isDelivery ? 'Alamat pengantaran' : 'Alamat (opsional)',
              ),
              validator: (v) => (_isDelivery && (v == null || v.trim().isEmpty))
                  ? 'Alamat wajib diisi untuk delivery'
                  : null,
            ),
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
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            const SizedBox(height: 16),
            Text(
              'Total pesanan: ${Fmt.rupiah(total)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Pesanan'),
            ),
          ],
        ),
      ),
    );
  }
}
