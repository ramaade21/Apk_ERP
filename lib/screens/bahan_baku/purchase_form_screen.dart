import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/helpers/ui_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/purchase_calculator.dart';
import '../../models/purchase.dart';
import '../../models/raw_material.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/raw_material_provider.dart';
import '../../repositories/raw_material_repository.dart';

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _supplier = TextEditingController();
  final _notes = TextEditingController();
  final _lines = <PurchaseLine>[];
  List<RawMaterial> _materials = [];
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _supplier.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final materials = await RawMaterialRepository().list();
    if (!mounted) return;
    setState(() => _materials = materials);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _addLine() async {
    final line = await showDialog<PurchaseLine>(
      context: context,
      builder: (_) => _LineDialog(materials: _materials),
    );
    if (line != null) setState(() => _lines.add(line));
  }

  Future<void> _submit() async {
    if (_lines.isEmpty) {
      showMessage(context, 'Tambahkan minimal satu bahan', error: true);
      return;
    }
    final purchases = context.read<PurchaseProvider>();
    final materials = context.read<RawMaterialProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final supplier = _supplier.text.trim();
    final notes = _notes.text.trim();

    setState(() => _saving = true);
    try {
      await purchases.create(
        supplier: supplier.isEmpty ? null : supplier,
        date: _date,
        lines: _lines,
        notes: notes.isEmpty ? null : notes,
      );
      await materials.load();
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Pembelian disimpan, stok bertambah')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Gagal menyimpan pembelian: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = PurchaseCalculator.total(_lines.map((l) => l.subtotal));
    return Scaffold(
      appBar: AppBar(title: const Text('Pembelian Baru')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(Fmt.date(_date)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _supplier,
            decoration: const InputDecoration(labelText: 'Supplier (opsional)'),
          ),
          const SizedBox(height: 20),
          Text('Bahan', style: Theme.of(context).textTheme.titleMedium),
          if (_materials.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  'Belum ada bahan baku. Tambahkan dulu di Lainnya > Bahan Baku.'),
            ),
          for (var i = 0; i < _lines.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_lines[i].materialName),
              subtitle: Text('${Fmt.qty(_lines[i].quantity)} ${_lines[i].unit} x '
                  '${Fmt.rupiah(_lines[i].price)} = ${Fmt.rupiah(_lines[i].subtotal)}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _lines.removeAt(i)),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _materials.isEmpty ? null : _addLine,
            icon: const Icon(Icons.add),
            label: const Text('Tambah bahan'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Catatan'),
          ),
          const SizedBox(height: 16),
          Text('Total: ${Fmt.rupiah(total)}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.save),
            label: const Text('Simpan Pembelian'),
          ),
        ],
      ),
    );
  }
}

class _LineDialog extends StatefulWidget {
  final List<RawMaterial> materials;
  const _LineDialog({required this.materials});

  @override
  State<_LineDialog> createState() => _LineDialogState();
}

class _LineDialogState extends State<_LineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  RawMaterial? _material;

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  double? get _qtyValue =>
      double.tryParse(_qty.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah bahan'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RawMaterial>(
                initialValue: _material,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Bahan'),
                items: [
                  for (final m in widget.materials)
                    DropdownMenuItem(
                        value: m, child: Text('${m.name} (${m.unit})')),
                ],
                validator: (v) => v == null ? 'Pilih bahan' : null,
                onChanged: (v) => setState(() => _material = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qty,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  suffixText: _material?.unit,
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                  if (n == null) return 'Harus berupa angka';
                  if (n <= 0) return 'Jumlah harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga beli per ${_material?.unit ?? 'satuan'}',
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Harus berupa angka';
                  if (n < 0) return 'Tidak boleh negatif';
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
            child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final m = _material!;
            Navigator.pop(
              context,
              PurchaseLine(
                materialId: m.id!,
                materialName: m.name,
                unit: m.unit,
                quantity: _qtyValue!,
                price: int.parse(_price.text.trim()),
              ),
            );
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
