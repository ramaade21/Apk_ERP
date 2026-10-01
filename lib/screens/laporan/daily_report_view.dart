import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_periods.dart';
import '../../models/report.dart';
import '../../models/sale.dart';
import '../../repositories/report_repository.dart';
import '../../repositories/sale_repository.dart';
import '../../widgets/report_widgets.dart';
import '../penjualan/sale_detail_screen.dart';

class DailyReportView extends StatefulWidget {
  final int refreshTick;
  const DailyReportView({super.key, this.refreshTick = 0});

  @override
  State<DailyReportView> createState() => _DailyReportViewState();
}

class _DailyReportViewState extends State<DailyReportView>
    with AutomaticKeepAliveClientMixin {
  DateTime _date = DateTime.now();
  PeriodSummary? _summary;
  List<ProductSales> _products = [];
  List<Sale> _sales = [];
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DailyReportView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) _load();
  }

  Future<void> _load() async {
    try {
      final range = ReportPeriods.day(_date);
      final reports = ReportRepository();
      final summary = await reports.summary(range);
      final products = await reports.productSales(range);
      final sales = await SaleRepository().list(date: _date);
      if (!mounted) return;
      setState(() {
        _error = null;
        _summary = summary;
        _products = products;
        _sales = sales;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _shift(int days) {
    setState(() => _date = DateTime(_date.year, _date.month, _date.day + days));
    _load();
  }

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => _date = d);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = _summary;
    if (s == null) {
      return Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Text('Gagal memuat laporan: $_error'),
      );
    }
    final netColor = s.isLoss ? AppTheme.lossColor : AppTheme.profitColor;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Hari sebelumnya',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(Fmt.date(_date)),
                ),
              ),
              IconButton(
                tooltip: 'Hari berikutnya',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SummaryRow(label: 'Tanggal', value: Fmt.date(_date)),
                  SummaryRow(label: 'Omzet', value: Fmt.rupiah(s.revenue)),
                  SummaryRow(label: 'HPP', value: Fmt.rupiah(s.cogs)),
                  SummaryRow(
                    label: 'Pembelian bahan baku',
                    value: Fmt.rupiah(s.purchases),
                    color: AppTheme.expenseColor,
                  ),
                  SummaryRow(
                    label: 'Operasional',
                    value: Fmt.rupiah(s.operational),
                    color: AppTheme.expenseColor,
                  ),
                  const Divider(),
                  SummaryRow(
                      label: 'Laba kotor',
                      value: Fmt.rupiah(s.grossProfit),
                      bold: true),
                  SummaryRow(
                    label: s.isLoss ? 'RUGI bersih' : 'Laba bersih',
                    value: Fmt.rupiah(s.netProfit.abs()),
                    bold: true,
                    color: netColor,
                  ),
                  const Divider(),
                  SummaryRow(
                      label: 'Jumlah transaksi',
                      value: '${s.transactions} transaksi'),
                  SummaryRow(
                      label: 'Jumlah customer',
                      value: '${s.customers} customer'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Laba bersih = omzet - HPP - operasional. Pembelian bahan baku '
              'ditampilkan sebagai informasi dan tidak dikurangkan lagi karena '
              'sudah terwakili oleh HPP.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          Text('Produk terjual', style: Theme.of(context).textTheme.titleMedium),
          if (_products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Belum ada produk terjual'),
            ),
          for (final p in _products)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(p.name),
              trailing: Text('${p.quantity}'),
            ),
          const SizedBox(height: 12),
          Text('Daftar transaksi',
              style: Theme.of(context).textTheme.titleMedium),
          if (_sales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Tidak ada transaksi pada tanggal ini'),
            ),
          for (final sale in _sales)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                  '${sale.customerName ?? 'Umum'} • ${Fmt.rupiah(sale.total)}'),
              subtitle: Text('${sale.invoiceNumber} • ${Fmt.time(sale.date)}'),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => SaleDetailScreen(sale: sale),
                ));
                if (mounted) _load();
              },
            ),
        ],
      ),
    );
  }
}
