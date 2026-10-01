import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_periods.dart';
import '../../models/raw_material.dart';
import '../../models/report.dart';
import '../../models/sale.dart';
import '../../repositories/raw_material_repository.dart';
import '../../repositories/report_repository.dart';
import '../../repositories/sale_repository.dart';
import '../../widgets/report_widgets.dart';
import '../penjualan/sale_detail_screen.dart';

class _DashboardData {
  final PeriodSummary today;
  final List<DaySummary> week;
  final List<ProductSales> topProducts;
  final List<Sale> recent;
  final List<RawMaterial> lowStock;

  const _DashboardData({
    required this.today,
    required this.week,
    required this.topProducts,
    required this.recent,
    required this.lowStock,
  });
}

class DashboardScreen extends StatefulWidget {
  /// Naik setiap kali tab dibuka, memicu muat ulang data.
  final int refreshTick;
  const DashboardScreen({super.key, this.refreshTick = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _DashboardData? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) _load();
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final reports = ReportRepository();
      final today = await reports.summary(ReportPeriods.day(now));
      final week = await reports.daily(ReportPeriods.lastDays(7, now));
      final top = await reports.productSales(ReportPeriods.day(now), limit: 5);
      final recent = (await SaleRepository().list()).take(5).toList();
      final low = (await RawMaterialRepository().list())
          .where((m) => m.isLow)
          .toList();
      if (!mounted) return;
      setState(() {
        _error = null;
        _data = _DashboardData(
          today: today,
          week: week,
          topProducts: top,
          recent: recent,
          lowStock: low,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: data == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text('Gagal memuat dashboard: $_error'),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _content(context, data),
            ),
    );
  }

  Widget _content(BuildContext context, _DashboardData d) {
    final t = d.today;
    final net = t.netProfit;
    final netColor = net < 0 ? AppTheme.lossColor : AppTheme.profitColor;
    final labels = [for (final day in d.week) '${day.date.day}/${day.date.month}'];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        Text(Fmt.date(DateTime.now()),
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            MetricCard(
              label: 'Omzet Hari Ini',
              value: Fmt.rupiah(t.revenue),
              icon: Icons.point_of_sale,
            ),
            MetricCard(
              label: 'Modal/HPP Hari Ini',
              value: Fmt.rupiah(t.cogs),
              icon: Icons.inventory_2_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            MetricCard(
              label: net < 0 ? 'Rugi Bersih Hari Ini' : 'Laba Bersih Hari Ini',
              value: Fmt.rupiah(net.abs()),
              icon: net < 0 ? Icons.trending_down : Icons.trending_up,
              color: netColor,
            ),
            MetricCard(
              label: 'Pengeluaran Bahan Baku Hari Ini',
              value: Fmt.rupiah(t.purchases),
              icon: Icons.shopping_basket_outlined,
              color: AppTheme.expenseColor,
            ),
            MetricCard(
              label: 'Jumlah Transaksi Hari Ini',
              value: '${t.transactions}',
              icon: Icons.receipt_long_outlined,
            ),
            MetricCard(
              label: 'Jumlah Customer Hari Ini',
              value: '${t.customers}',
              icon: Icons.people_outline,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (d.lowStock.isNotEmpty)
          Card(
            color: const Color(0xFFFFF3E0),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppTheme.expenseColor),
                      SizedBox(width: 8),
                      Text('Stok Menipis',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.expenseColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final m in d.lowStock)
                    Text(
                      '${m.name}: ${Fmt.qty(m.stock)} ${m.unit} '
                      '(minimum ${Fmt.qty(m.minimumStock)})',
                      style: const TextStyle(color: Colors.black87),
                    ),
                ],
              ),
            ),
          ),
        BarChartCard(
          title: 'Omzet 7 hari terakhir',
          values: [for (final day in d.week) day.revenue.toDouble()],
          labels: labels,
          color: Theme.of(context).colorScheme.primary,
          footer: 'Total: ${Fmt.rupiah(d.week.fold<int>(0, (s, e) => s + e.revenue))}',
        ),
        BarChartCard(
          title: 'Laba bersih 7 hari terakhir',
          values: [for (final day in d.week) day.netProfit.toDouble()],
          labels: labels,
          color: AppTheme.profitColor,
          negativeColor: AppTheme.lossColor,
          footer: 'Total: ${Fmt.rupiah(d.week.fold<int>(0, (s, e) => s + e.netProfit))}',
        ),
        const SizedBox(height: 8),
        Text('Produk terlaris hari ini',
            style: Theme.of(context).textTheme.titleMedium),
        if (d.topProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Belum ada penjualan hari ini'),
          ),
        for (final p in d.topProducts)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(p.name),
            trailing: Text('${p.quantity} porsi'),
          ),
        const SizedBox(height: 8),
        Text('Transaksi terbaru',
            style: Theme.of(context).textTheme.titleMedium),
        if (d.recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Belum ada transaksi'),
          ),
        for (final s in d.recent)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${s.customerName ?? 'Umum'} • ${Fmt.rupiah(s.total)}'),
            subtitle: Text('${s.invoiceNumber} • ${Fmt.dateTime(s.date)}'),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => SaleDetailScreen(sale: s),
              ));
              if (mounted) _load();
            },
          ),
      ],
    );
  }
}
