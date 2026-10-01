import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/helpers/ui_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/raw_material.dart';
import '../../providers/raw_material_provider.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RawMaterialProvider>().load();
    });
  }

  Future<void> _openForm({RawMaterial? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MaterialForm(existing: existing),
    );
  }

  Future<void> _useStock(RawMaterial m) async {
    final provider = context.read<RawMaterialProvider>();
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final qty = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pakai ${m.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Jumlah dipakai (${m.unit})',
              helperText: 'Stok saat ini: ${Fmt.qty(m.stock)} ${m.unit}',
            ),
            validator: (v) {
              final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
              if (n == null) return 'Harus berupa angka';
              if (n <= 0) return 'Jumlah harus lebih dari 0';
              if (n > m.stock) return 'Melebihi stok';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx,
                  double.parse(controller.text.trim().replaceAll(',', '.')));
            },
            child: const Text('Kurangi stok'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (qty == null) return;
    try {
      await provider.useStock(m, qty);
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Gagal mengurangi stok: $e', error: true);
    }
  }

  Future<void> _delete(RawMaterial m) async {
    final provider = context.read<RawMaterialProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus bahan?'),
        content: Text('${m.name} akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await provider.remove(m);
    if (!mounted) return;
    if (!deleted) {
      showMessage(context, 'Bahan sudah dipakai di pembelian, tidak bisa dihapus',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RawMaterialProvider>();
    final low = provider.lowStock.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Bahan Baku')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Bahan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBar(
              hintText: 'Cari nama atau kategori',
              leading: const Icon(Icons.search),
              onChanged: (v) => context.read<RawMaterialProvider>().search(v),
            ),
          ),
          if (low > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: AppTheme.expenseColor, size: 18),
                  const SizedBox(width: 6),
                  Text('$low bahan stok menipis',
                      style: const TextStyle(color: AppTheme.expenseColor)),
                ],
              ),
            ),
          Expanded(
            child: provider.materials.isEmpty
                ? const Center(child: Text('Belum ada bahan baku'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    itemCount: provider.materials.length,
                    itemBuilder: (context, i) {
                      final m = provider.materials[i];
                      return Card(
                        child: ListTile(
                          onTap: () => _openForm(existing: m),
                          title: Text(m.name),
                          subtitle: Text(
                            '${m.category ?? '-'}\n'
                            'Stok ${Fmt.qty(m.stock)} ${m.unit} • '
                            'Minimum ${Fmt.qty(m.minimumStock)} ${m.unit}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (m.isLow)
                                const Chip(
                                  label: Text('Stok Menipis'),
                                  backgroundColor: Color(0xFFFFE0B2),
                                  labelStyle: TextStyle(
                                      color: AppTheme.expenseColor,
                                      fontSize: 11),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'use') _useStock(m);
                                  if (v == 'delete') _delete(m);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'use', child: Text('Pakai stok')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Hapus')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MaterialForm extends StatefulWidget {
  final RawMaterial? existing;
  const _MaterialForm({this.existing});

  @override
  State<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends State<_MaterialForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _stock;
  late final TextEditingController _min;
  late String _category;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _stock = TextEditingController(text: e == null ? '0' : Fmt.qty(e.stock));
    _min = TextEditingController(text: e == null ? '0' : Fmt.qty(e.minimumStock));
    _category = AppConstants.materialCategories.contains(e?.category)
        ? e!.category!
        : AppConstants.materialCategories.last;
    _unit = AppConstants.materialUnits.contains(e?.unit)
        ? e!.unit
        : AppConstants.materialUnits.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _stock.dispose();
    _min.dispose();
    super.dispose();
  }

  String? _validateQty(String? v) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Harus berupa angka';
    if (n < 0) return 'Tidak boleh negatif';
    return null;
  }

  double _parse(String v) => double.parse(v.trim().replaceAll(',', '.'));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<RawMaterialProvider>();
    final navigator = Navigator.of(context);
    try {
      await provider.save(
        existing: widget.existing,
        name: _name.text.trim(),
        category: _category,
        unit: _unit,
        stock: _parse(_stock.text),
        minimumStock: _parse(_min.text),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Gagal menyimpan bahan: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
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
              Text(isNew ? 'Tambah Bahan Baku' : 'Edit Bahan Baku',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama bahan'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama bahan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final c in AppConstants.materialCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _unit,
                decoration: const InputDecoration(labelText: 'Satuan'),
                items: [
                  for (final u in AppConstants.materialUnits)
                    DropdownMenuItem(value: u, child: Text(u)),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
              ),
              if (isNew) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stock,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Stok awal'),
                  validator: _validateQty,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _min,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Stok minimum'),
                validator: _validateQty,
              ),
              if (!isNew)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                      'Stok berubah lewat Pembelian (bertambah) dan menu Pakai stok (berkurang).'),
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
