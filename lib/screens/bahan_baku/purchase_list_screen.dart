import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/purchase.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/raw_material_provider.dart';
import 'purchase_form_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().load();
    });
  }

  Future<void> _pickDate() async {
    final provider = context.read<PurchaseProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.dateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) await provider.setDate(picked);
  }

  Future<void> _showDetail(Purchase p) async {
    final purchases = context.read<PurchaseProvider>();
    final materials = context.read<RawMaterialProvider>();
    final items = await purchases.items(p.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.purchaseNumber, style: Theme.of(ctx).textTheme.titleLarge),
            Text('${Fmt.date(p.date)} • ${p.supplier ?? 'Tanpa supplier'}'),
            const Divider(height: 24),
            for (final it in items)
              Text('${it.materialName}: ${Fmt.qty(it.quantity)} ${it.unit} x '
                  '${Fmt.rupiah(it.price)} = ${Fmt.rupiah(it.subtotal)}'),
            const SizedBox(height: 8),
            Text('Total: ${Fmt.rupiah(p.total)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (p.notes != null) ...[
              const SizedBox(height: 8),
              Text('Catatan: ${p.notes}'),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus pembelian (stok dikembalikan)'),
              onPressed: () async {
                Navigator.pop(ctx);
                await purchases.remove(p.id);
                await materials.load();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final filter = provider.dateFilter;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembelian'),
        actions: [
          if (filter != null)
            TextButton.icon(
              onPressed: () => context.read<PurchaseProvider>().setDate(null),
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
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PurchaseFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Pembelian'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBar(
              hintText: 'Cari nomor atau supplier',
              leading: const Icon(Icons.search),
              onChanged: (v) => context.read<PurchaseProvider>().setQuery(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text('${provider.purchases.length} pembelian')),
                Text(
                  Fmt.rupiah(provider.totalSpent),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.expenseColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.purchases.isEmpty
                ? const Center(child: Text('Belum ada pembelian'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    itemCount: provider.purchases.length,
                    itemBuilder: (context, i) {
                      final p = provider.purchases[i];
                      return Card(
                        child: ListTile(
                          onTap: () => _showDetail(p),
                          title: Text(
                              '${p.supplier ?? 'Tanpa supplier'} • ${Fmt.rupiah(p.total)}'),
                          subtitle:
                              Text('${p.purchaseNumber}\n${Fmt.date(p.date)}'),
                          isThreeLine: true,
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
