import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_periods.dart';
import '../../models/report.dart';
import '../../repositories/report_repository.dart';
import '../../widgets/report_widgets.dart';

class MonthlyReportView extends StatefulWidget {
  final int refreshTick;
  const MonthlyReportView({super.key, this.refreshTick = 0});

  @override
  State<MonthlyReportView> createState() => _MonthlyReportViewState();
}

class _MonthlyReportViewState extends State<MonthlyReportView>
    with AutomaticKeepAliveClientMixin {
  late int _year;
  late int _month;
  PeriodSummary? _summary;
  List<DaySummary> _days = [];
  List<ProductSales> _products = [];
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _load();
  }

  @override
  void didUpdateWidget(covariant MonthlyReportView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) _load();
  }

  Future<void> _load() async {
    try {
      final range = ReportPeriods.month(_year, _month);
      final reports = ReportRepository();
      final summary = await reports.summary(range);
      final days = await reports.daily(range);
      final products = await reports.productSales(range);
      if (!mounted) return;
      setState(() {
        _error = null;
        _summary = summary;
        _days = days;
        _products = products;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = _summary;
    final thisYear = DateTime.now().year;
    final years = [for (var y = thisYear - 5; y <= thisYear + 1; y++) y];
    if (!years.contains(_year)) years.add(_year);
    years.sort();

    final picker = Row(
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<int>(
            initialValue: _month,
            decoration: const InputDecoration(labelText: 'Bulan'),
            items: [
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(
                    value: m, child: Text(AppConstants.monthNames[m - 1])),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _month = v);
              _load();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            initialValue: _year,
            decoration: const InputDecoration(labelText: 'Tahun'),
            items: [
              for (final y in years)
                DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _year = v);
              _load();
            },
          ),
        ),
      ],
    );

    if (s == null) {
      return Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: picker),
          Expanded(
            child: Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text('Gagal memuat laporan: $_error'),
            ),
          ),
        ],
      );
    }

    final labels = [for (final d in _days) '${d.date.day}'];
    final netColor = s.isLoss ? AppTheme.lossColor : AppTheme.profitColor;
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          picker,
          const SizedBox(height: 8),
          Text('${AppConstants.monthNames[_month - 1]} $_year',
              style: Theme.of(context).textTheme.titleLarge),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SummaryRow(label: 'Total omzet', value: Fmt.rupiah(s.revenue)),
                  SummaryRow(label: 'Total HPP', value: Fmt.rupiah(s.cogs)),
                  SummaryRow(
                    label: 'Total pembelian bahan baku',
                    value: Fmt.rupiah(s.purchases),
                    color: AppTheme.expenseColor,
                  ),
                  SummaryRow(
                    label: 'Total biaya operasional',
                    value: Fmt.rupiah(s.operational),
                    color: AppTheme.expenseColor,
                  ),
                  const Divider(),
                  SummaryRow(
                      label: 'Total laba kotor',
                      value: Fmt.rupiah(s.grossProfit),
                      bold: true),
                  SummaryRow(
                    label: s.isLoss ? 'Total RUGI bersih' : 'Total laba bersih',
                    value: Fmt.rupiah(s.netProfit.abs()),
                    bold: true,
                    color: netColor,
                  ),
                  const Divider(),
                  SummaryRow(
                      label: 'Total transaksi', value: '${s.transactions}'),
                  SummaryRow(
                      label: 'Total customer', value: '${s.customers}'),
                ],
              ),
            ),
          ),
          BarChartCard(
            title: 'Omzet per hari',
            values: [for (final d in _days) d.revenue.toDouble()],
            labels: labels,
            color: scheme.primary,
          ),
          BarChartCard(
            title: 'Laba bersih per hari',
            values: [for (final d in _days) d.netProfit.toDouble()],
            labels: labels,
            color: AppTheme.profitColor,
            negativeColor: AppTheme.lossColor,
          ),
          BarChartCard(
            title: 'Pengeluaran per hari (bahan baku + operasional)',
            values: [for (final d in _days) d.totalExpense.toDouble()],
            labels: labels,
            color: AppTheme.expenseColor,
          ),
          BarChartCard(
            title: 'Jumlah transaksi per hari',
            values: [for (final d in _days) d.transactions.toDouble()],
            labels: labels,
            color: scheme.tertiary,
          ),
          const SizedBox(height: 8),
          Text('Laporan produk', style: Theme.of(context).textTheme.titleMedium),
          if (_products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Belum ada penjualan pada bulan ini'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Produk')),
                  DataColumn(label: Text('Qty'), numeric: true),
                  DataColumn(label: Text('Omzet'), numeric: true),
                  DataColumn(label: Text('HPP'), numeric: true),
                  DataColumn(label: Text('Laba'), numeric: true),
                ],
                rows: [
                  for (final p in _products)
                    DataRow(cells: [
                      DataCell(Text(p.name)),
                      DataCell(Text('${p.quantity}')),
                      DataCell(Text(Fmt.rupiah(p.revenue))),
                      DataCell(Text(Fmt.rupiah(p.cost))),
                      DataCell(Text(
                        Fmt.rupiah(p.profit),
                        style: TextStyle(
                          color: p.profit < 0
                              ? AppTheme.lossColor
                              : AppTheme.profitColor,
                        ),
                      )),
                    ]),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Omzet per produk dihitung sebelum diskon transaksi.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
