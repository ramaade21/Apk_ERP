import 'package:flutter/material.dart';

import 'bahan_baku/expense_list_screen.dart';
import 'bahan_baku/material_list_screen.dart';
import 'bahan_baku/purchase_list_screen.dart';
import 'customer/customer_list_screen.dart';
import 'laporan/export_screen.dart';
import 'pengaturan/backup_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'laporan/report_screen.dart';
import 'penjualan/sale_list_screen.dart';
import 'pesanan/order_list_screen.dart';
import 'produk/product_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _tick = 0; // naik tiap ganti tab agar Dashboard/Laporan memuat ulang

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(refreshTick: _tick),
      const SaleListScreen(),
      const OrderListScreen(),
      ReportScreen(refreshTick: _tick),
      const _MoreScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          _tick++;
        }),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Penjualan'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Pesanan'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Laporan'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz), label: 'Lainnya'),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    void open(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    Widget item(IconData icon, String label, {Widget? page, int? phase}) {
      return ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: page == null ? Text('Segera hadir (Fase $phase)') : null,
        enabled: page != null,
        trailing: const Icon(Icons.chevron_right),
        onTap: page == null ? null : () => open(page),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        children: [
          item(Icons.ramen_dining, 'Produk', page: const ProductListScreen()),
          item(Icons.people, 'Customer', page: const CustomerListScreen()),
          item(Icons.inventory_2, 'Bahan Baku', page: const MaterialListScreen()),
          item(Icons.shopping_basket, 'Pembelian', page: const PurchaseListScreen()),
          item(Icons.payments, 'Pengeluaran', page: const ExpenseListScreen()),
          item(Icons.file_download, 'Export Laporan', page: const ExportScreen()),
          item(Icons.backup, 'Backup / Restore', page: const BackupScreen()),
          item(Icons.settings, 'Pengaturan', phase: 5),
        ],
      ),
    );
  }
}
