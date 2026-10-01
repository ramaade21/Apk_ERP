import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/helpers/ui_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/expense_provider.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().load();
    });
  }

  Future<void> _pickDate() async {
    final provider = context.read<ExpenseProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.dateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) await provider.setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final filter = provider.dateFilter;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran'),
        actions: [
          if (filter != null)
            TextButton.icon(
              onPressed: () => context.read<ExpenseProvider>().setDate(null),
              icon: const Icon(Icons.close),
              label: Text(Fmt.date(filter)),
            ),
          IconButton(
            tooltip: 'Filter tanggal',
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickDate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const _ExpenseForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Pengeluaran'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBar(
              hintText: 'Cari nama atau kategori',
              leading: const Icon(Icons.search),
              onChanged: (v) => context.read<ExpenseProvider>().setQuery(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Expanded(child: Text('Biaya operasional')),
                Text(
                  Fmt.rupiah(provider.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.expenseColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.expenses.isEmpty
                ? const Center(child: Text('Belum ada pengeluaran'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    itemCount: provider.expenses.length,
                    itemBuilder: (context, i) {
                      final e = provider.expenses[i];
                      return Card(
                        child: ListTile(
                          title: Text('${e.name} • ${Fmt.rupiah(e.amount)}'),
                          subtitle: Text([
                            '${e.category} • ${Fmt.date(e.date)}',
                            if (e.notes != null) e.notes!,
                          ].join('\n')),
                          isThreeLine: e.notes != null,
                          trailing: IconButton(
                            tooltip: 'Hapus',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                context.read<ExpenseProvider>().remove(e.id),
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

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm();

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _category = AppConstants.expenseCategories.first;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ExpenseProvider>();
    final navigator = Navigator.of(context);
    final notes = _notes.text.trim();
    try {
      await provider.add(
        category: _category,
        name: _name.text.trim(),
        amount: int.parse(_amount.text.trim()),
        date: _date,
        notes: notes.isEmpty ? null : notes,
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Gagal menyimpan pengeluaran: $e', error: true);
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
              Text('Tambah Pengeluaran',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(Fmt.date(_date)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final c in AppConstants.expenseCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nama pengeluaran'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama pengeluaran wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Harus berupa angka';
                  if (n < 0) return 'Tidak boleh negatif';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Keterangan'),
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
