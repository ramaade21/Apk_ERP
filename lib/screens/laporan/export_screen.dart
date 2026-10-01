import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/helpers/ui_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_periods.dart';
import '../../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _service = ExportService();
  bool _monthly = false;
  DateTime _date = DateTime.now();
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;
  bool _busy = false;

  DateRange get _range =>
      _monthly ? ReportPeriods.month(_year, _month) : ReportPeriods.day(_date);

  /// Untuk nama file: 2026-09-29 atau 2026-09.
  String get _label => _monthly
      ? '$_year-${_month.toString().padLeft(2, '0')}'
      : DateFormat('yyyy-MM-dd').format(_date);

  String get _title => _monthly
      ? 'Laporan Bulanan ${AppConstants.monthNames[_month - 1]} $_year'
      : 'Laporan Harian ${Fmt.date(_date)}';

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _export(
    String fileName,
    Future<List<List<Object?>>> Function() rows,
  ) async {
    setState(() => _busy = true);
    try {
      final data = await rows();
      final file = await _service.saveCsv('$fileName.csv', data);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: fileName,
      );
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Export gagal: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thisYear = DateTime.now().year;
    final years = [for (var y = thisYear - 5; y <= thisYear + 1; y++) y];

    Widget tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.ios_share),
          enabled: !_busy,
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Export Laporan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Harian')),
              ButtonSegment(value: true, label: Text('Bulanan')),
            ],
            selected: {_monthly},
            onSelectionChanged: (s) => setState(() => _monthly = s.first),
          ),
          const SizedBox(height: 12),
          if (_monthly)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Bulan'),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                            value: m,
                            child: Text(AppConstants.monthNames[m - 1])),
                    ],
                    onChanged: (v) => setState(() => _month = v ?? _month),
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
                    onChanged: (v) => setState(() => _year = v ?? _year),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(Fmt.date(_date)),
            ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'File CSV dapat dibuka di Excel atau Google Sheets. '
              'Format Excel (.xlsx) dan PDF menyusul.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          tile(
            Icons.summarize,
            _monthly ? 'Laporan Bulanan' : 'Laporan Harian',
            'Ringkasan, ${_monthly ? 'rincian per hari, ' : ''}dan penjualan per produk',
            () => _export(
              _monthly ? 'laporan-bulanan-$_label' : 'laporan-harian-$_label',
              () => _service.reportRows(_range,
                  title: _title, includeDaily: _monthly),
            ),
          ),
          tile(
            Icons.point_of_sale,
            'Penjualan',
            'Semua transaksi pada periode ini',
            () => _export('laporan-penjualan-$_label',
                () => _service.salesRows(_range)),
          ),
          tile(
            Icons.people,
            'Customer',
            'Seluruh customer beserta total belanja',
            () => _export(
              'laporan-customer-${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
              () => _service.customerRows(),
            ),
          ),
          tile(
            Icons.shopping_basket,
            'Pembelian Bahan Baku',
            'Rincian bahan yang dibeli',
            () => _export('laporan-pembelian-$_label',
                () => _service.purchaseRows(_range)),
          ),
          tile(
            Icons.payments,
            'Pengeluaran',
            'Biaya operasional',
            () => _export('laporan-pengeluaran-$_label',
                () => _service.expenseRows(_range)),
          ),
          tile(
            Icons.trending_up,
            'Laba/Rugi',
            'Omzet, HPP, biaya operasional, dan laba bersih',
            () => _export('laporan-laba-rugi-$_label',
                () => _service.profitLossRows(_range, title: _title)),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
