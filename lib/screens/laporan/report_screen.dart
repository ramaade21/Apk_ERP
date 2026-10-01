import 'package:flutter/material.dart';

import 'daily_report_view.dart';
import 'monthly_report_view.dart';

class ReportScreen extends StatelessWidget {
  final int refreshTick;
  const ReportScreen({super.key, this.refreshTick = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Harian'), Tab(text: 'Bulanan')],
          ),
        ),
        body: TabBarView(
          children: [
            DailyReportView(refreshTick: refreshTick),
            MonthlyReportView(refreshTick: refreshTick),
          ],
        ),
      ),
    );
  }
}
