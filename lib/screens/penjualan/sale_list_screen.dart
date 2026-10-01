import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/sale_calculator.dart';
import '../../models/sale.dart';
import '../../providers/sale_provider.dart';
import 'sale_detail_screen.dart';
import 'sale_form_screen.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().load();
    });
  }

  Future<void> _pickDate() async {
    final provider = context.read<SaleProvider>();
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
    final provider = context.watch<SaleProvider>();
    final filter = provider.dateFilter;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjualan'),
        actions: [
          if (filter != null)
            TextButton.icon(
              onPressed: () => context.read<SaleProvider>().setDate(null),
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
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SaleFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Transaksi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBar(
              hintText: 'Cari nomor transaksi atau customer',
              leading: const Icon(Icons.search),
              onChanged: (v) => context.read<SaleProvider>().setQuery(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${provider.sales.length} transaksi • '
                    'Omzet ${Fmt.rupiah(provider.totalRevenue)}',
                  ),
                ),
                Text(
                  '${SaleCalculator.label(provider.totalProfit)} '
                  '${Fmt.rupiah(provider.totalProfit.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: provider.totalProfit < 0
                        ? AppTheme.lossColor
                        : AppTheme.profitColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.sales.isEmpty
                ? const Center(child: Text('Belum ada transaksi'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    itemCount: provider.sales.length,
                    itemBuilder: (context, i) => _SaleCard(sale: provider.sales[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final color = sale.isLoss ? AppTheme.lossColor : AppTheme.profitColor;
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SaleDetailScreen(sale: sale),
          ),
        ),
        title: Text('${sale.customerName ?? 'Umum'} • ${Fmt.rupiah(sale.total)}'),
        subtitle: Text(
          '${sale.invoiceNumber}\n${Fmt.dateTime(sale.date)} • ${sale.orderType}',
        ),
        isThreeLine: true,
        trailing: Text(
          '${sale.isLoss ? 'Rugi' : 'Laba'}\n${Fmt.rupiah(sale.profit.abs())}',
          textAlign: TextAlign.right,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
