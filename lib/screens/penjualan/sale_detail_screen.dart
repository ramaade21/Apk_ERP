import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/helpers/ui_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/receipt_builder.dart';
import '../../models/sale.dart';
import '../../providers/sale_provider.dart';
import '../../repositories/sale_repository.dart';

class SaleDetailScreen extends StatelessWidget {
  final Sale sale;
  const SaleDetailScreen({super.key, required this.sale});

  Future<void> _delete(BuildContext context) async {
    final provider = context.read<SaleProvider>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: Text('${sale.invoiceNumber} akan dihapus permanen.'),
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
    if (ok == true) {
      await provider.remove(sale.id);
      navigator.pop();
    }
  }

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      final items = await SaleRepository().items(sale.id);
      final text = ReceiptBuilder.build(sale, items);
      await Share.share(text, subject: 'Struk ${sale.invoiceNumber}');
    } catch (e) {
      if (!context.mounted) return;
      showMessage(context, 'Gagal membagikan struk: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = sale.isLoss ? AppTheme.lossColor : AppTheme.profitColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(sale.invoiceNumber),
        actions: [
          IconButton(
            tooltip: 'Bagikan struk',
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(context),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Tanggal', Fmt.dateTime(sale.date)),
          _row('Customer', sale.customerName ?? 'Umum'),
          _row('Jenis pesanan', sale.orderType),
          if (sale.notes != null) _row('Catatan', sale.notes!),
          const Divider(height: 32),
          FutureBuilder<List<SaleItem>>(
            future: SaleRepository().items(sale.id),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  for (final it in snap.data!)
                    _row('${it.productName} x ${it.quantity}',
                        Fmt.rupiah(it.subtotal)),
                ],
              );
            },
          ),
          const Divider(height: 32),
          _row('Subtotal', Fmt.rupiah(sale.subtotal)),
          _row('Diskon', Fmt.rupiah(sale.discount)),
          _row('Total', Fmt.rupiah(sale.total), bold: true),
          _row('Modal / HPP', Fmt.rupiah(sale.totalCost)),
          _row(
            sale.isLoss ? 'RUGI' : 'Laba',
            Fmt.rupiah(sale.profit.abs()),
            bold: true,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : null,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
