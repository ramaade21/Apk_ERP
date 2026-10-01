import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer_order.dart';
import '../../providers/order_provider.dart';
import 'order_form_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final stats = provider.stats;
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const OrderFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Pesanan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total pesanan: ${stats.totalOrders} • '
                    'Total customer: ${stats.totalCustomers} • '
                    'Customer baru bulan ini: ${stats.newCustomersThisMonth}',
                  ),
                  if (stats.topCustomers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Customer yang sering pesan',
                        style: Theme.of(context).textTheme.titleSmall),
                    for (final c in stats.topCustomers)
                      Text('${c.name} - ${c.count} pesanan'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SearchBar(
            hintText: 'Cari nama, nomor WhatsApp, atau alamat',
            leading: const Icon(Icons.search),
            onChanged: (v) => context.read<OrderProvider>().setQuery(v),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Semua'),
                    selected: provider.statusFilter == null,
                    onSelected: (_) =>
                        context.read<OrderProvider>().setStatus(null),
                  ),
                ),
                for (final s in AppConstants.orderStatuses)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: provider.statusFilter == s,
                      onSelected: (_) =>
                          context.read<OrderProvider>().setStatus(s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (provider.orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Belum ada pesanan')),
            )
          else
            for (final o in provider.orders) _OrderCard(order: o),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CustomerOrder order;
  const _OrderCard({required this.order});

  Future<void> _showDetail(BuildContext context) async {
    final provider = context.read<OrderProvider>();
    final items = await provider.items(order.id);
    if (!context.mounted) return;
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
            Text(order.customerName ?? '-',
                style: Theme.of(ctx).textTheme.titleLarge),
            if (order.customerPhone != null) Text(order.customerPhone!),
            if (order.address != null) Text(order.address!),
            Text('${Fmt.dateTime(order.date)} • ${order.orderType}'),
            const Divider(height: 24),
            for (final it in items)
              Text('${it.productName} x ${it.quantity} = ${Fmt.rupiah(it.subtotal)}'),
            const SizedBox(height: 8),
            Text('Total: ${Fmt.rupiah(order.total)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (order.notes != null) ...[
              const SizedBox(height: 8),
              Text('Catatan: ${order.notes}'),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus pesanan'),
              onPressed: () async {
                Navigator.pop(ctx);
                await provider.remove(order.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => _showDetail(context),
        title: Text('${order.customerName ?? '-'} • ${Fmt.rupiah(order.total)}'),
        subtitle: Text('${Fmt.dateTime(order.date)} • ${order.orderType}'),
        trailing: PopupMenuButton<String>(
          tooltip: 'Ubah status',
          onSelected: (s) =>
              context.read<OrderProvider>().updateStatus(order.id, s),
          itemBuilder: (_) => [
            for (final s in AppConstants.orderStatuses)
              PopupMenuItem(value: s, child: Text(s)),
          ],
          child: Chip(label: Text(order.status)),
        ),
      ),
    );
  }
}
