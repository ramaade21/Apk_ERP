import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/helpers/ui_helpers.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Customer')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBar(
              hintText: 'Cari nama, nomor HP, atau alamat',
              leading: const Icon(Icons.search),
              onChanged: (v) => context.read<CustomerProvider>().search(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Total customer: ${provider.customers.length}'),
            ),
          ),
          Expanded(
            child: provider.customers.isEmpty
                ? const Center(child: Text('Belum ada customer'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    itemCount: provider.customers.length,
                    itemBuilder: (context, i) {
                      final c = provider.customers[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(c.name.characters.first.toUpperCase()),
                          ),
                          title: Text(c.name),
                          subtitle: Text([
                            if (c.phone != null) c.phone!,
                            if (c.address != null) c.address!,
                          ].join('\n')),
                          isThreeLine: c.phone != null && c.address != null,
                          onTap: () => _openForm(context, existing: c),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Riwayat',
                                icon: const Icon(Icons.history),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        CustomerDetailScreen(customer: c),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Hapus',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(context, c),
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

  Future<void> _confirmDelete(BuildContext context, Customer c) async {
    final provider = context.read<CustomerProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus customer?'),
        content: Text(
            '${c.name} akan dihapus. Riwayat transaksi tetap tersimpan sebagai transaksi umum.'),
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
    if (ok == true) await provider.remove(c);
  }

  Future<void> _openForm(BuildContext context, {Customer? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CustomerForm(existing: existing),
    );
  }
}

class _CustomerForm extends StatefulWidget {
  final Customer? existing;
  const _CustomerForm({this.existing});

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _address = TextEditingController(text: e?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<CustomerProvider>();
    final navigator = Navigator.of(context);
    try {
      await provider.save(
        existing: widget.existing,
        name: _name.text,
        phone: _phone.text,
        address: _address.text,
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Gagal menyimpan customer: $e', error: true);
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
                widget.existing == null ? 'Tambah Customer' : 'Edit Customer',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama customer'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama customer wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Nomor WhatsApp (opsional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Alamat'),
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
