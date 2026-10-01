import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/helpers/ui_helpers.dart';
import '../../providers/customer_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/raw_material_provider.dart';
import '../../providers/sale_provider.dart';
import '../../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = BackupService();
  bool _busy = false;

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      final file = await _service.createBackup();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Backup Bakso Mie Ayam',
        text: 'Backup database Bakso Mie Ayam',
      );
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Backup gagal: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final result = await FilePicker.pickFiles(type: FileType.any);
    final path = (result == null || result.files.isEmpty)
        ? null
        : result.files.first.path;
    if (path == null) return;
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore database?'),
        content: const Text(
          'Seluruh data saat ini akan DIGANTI dengan isi file backup. '
          'Tindakan ini tidak dapat dibatalkan. Pastikan Anda sudah membuat '
          'backup data saat ini.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, restore')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.restoreFrom(path);
      if (!mounted) return;
      await _reloadAll();
      if (!mounted) return;
      showMessage(context, 'Restore berhasil. Data telah dipulihkan.');
    } on FormatException catch (e) {
      if (!mounted) return;
      showMessage(context, 'Restore dibatalkan: ${e.message}', error: true);
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Restore gagal: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reloadAll() async {
    await context.read<ProductProvider>().load();
    if (!mounted) return;
    await context.read<CustomerProvider>().load();
    if (!mounted) return;
    await context.read<SaleProvider>().load();
    if (!mounted) return;
    await context.read<OrderProvider>().load();
    if (!mounted) return;
    await context.read<RawMaterialProvider>().load();
    if (!mounted) return;
    await context.read<PurchaseProvider>().load();
    if (!mounted) return;
    await context.read<ExpenseProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup / Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backup Database',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Membuat salinan seluruh data lalu membukanya di menu '
                    'Bagikan. Simpan ke Google Drive, WhatsApp, atau Files '
                    'agar data aman walaupun aplikasi dihapus atau HP hilang.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _backup,
                    icon: const Icon(Icons.backup),
                    label: const Text('Backup Sekarang'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Restore Database',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih file backup (.db) untuk memulihkan data. Data saat '
                    'ini akan diganti. Sebelum diganti, aplikasi menyimpan '
                    'cadangan pengaman otomatis.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.restore),
                    label: const Text('Pilih File Backup'),
                  ),
                ],
              ),
            ),
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
