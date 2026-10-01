/// Rentang tanggal [start, end) untuk laporan.
class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange(this.start, this.end);

  /// Daftar tanggal (00:00) di dalam rentang.
  List<DateTime> get dates {
    final out = <DateTime>[];
    var d = start;
    while (d.isBefore(end)) {
      out.add(d);
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return out;
  }
}

class ReportPeriods {
  static DateRange day(DateTime d) =>
      DateRange(DateTime(d.year, d.month, d.day), DateTime(d.year, d.month, d.day + 1));

  static DateRange month(int year, int month) =>
      DateRange(DateTime(year, month, 1), DateTime(year, month + 1, 1));

  /// [n] hari terakhir termasuk hari ini.
  static DateRange lastDays(int n, DateTime today) => DateRange(
        DateTime(today.year, today.month, today.day - (n - 1)),
        DateTime(today.year, today.month, today.day + 1),
      );
}
