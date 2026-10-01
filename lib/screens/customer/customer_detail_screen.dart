import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/customer.dart';
import '../../models/customer_order.dart';
import '../../models/sale.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/sale_repository.dart';

class _DetailData {
  final CustomerStats stats;
  final List<Sale> sales;
  final List<CustomerOrder> orders;
  const _DetailData(this.stats, this.sales, this.orders);
}

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  Future<_DetailData> _load() async {
    final id = customer.id!;
    final stats = await CustomerRepository().stats(id);
    final sales = await SaleRepository().list(customerId: id);
    final orders = await OrderRepository().list(customerId: id);
    return _DetailData(stats, sales, orders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: FutureBuilder<_DetailData>(
        future: _load(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Gagal memuat data: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('WhatsApp: ${customer.phone ?? '-'}'),
              Text('Alamat: ${customer.address ?? '-'}'),
              const Divider(height: 24),
              Text('Total transaksi: ${d.stats.saleCount}'),
              Text('Total nominal pembelian: ${Fmt.rupiah(d.stats.saleTotal)}'),
              Text('Jumlah pesanan: ${d.stats.orderCount}'),
              const Divider(height: 24),
              Text('Riwayat transaksi',
                  style: Theme.of(context).textTheme.titleMedium),
              if (d.sales.isEmpty) const Text('Belum ada transaksi'),
              for (final s in d.sales)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${s.invoiceNumber} • ${Fmt.rupiah(s.total)}'),
                  subtitle: Text(Fmt.dateTime(s.date)),
                ),
              const SizedBox(height: 12),
              Text('Riwayat pesanan',
                  style: Theme.of(context).textTheme.titleMedium),
              if (d.orders.isEmpty) const Text('Belum ada pesanan'),
              for (final o in d.orders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${o.status} • ${Fmt.rupiah(o.total)}'),
                  subtitle: Text('${Fmt.dateTime(o.date)} • ${o.orderType}'),
                ),
            ],
          );
        },
      ),
    );
  }
}
