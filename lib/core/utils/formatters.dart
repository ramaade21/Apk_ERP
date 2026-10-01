import 'package:intl/intl.dart';

class Fmt {
  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  static final _date = DateFormat('dd/MM/yyyy');
  static final _time = DateFormat('HH:mm');

  static String rupiah(num value) => _rupiah.format(value);
  static String date(DateTime d) => _date.format(d);
  static String time(DateTime d) => _time.format(d);
  static String dateTime(DateTime d) => '${date(d)} ${time(d)}';

  /// Jumlah bahan tanpa nol berlebih: 10.0 -> "10", 2.5 -> "2.5".
  static String qty(num v) {
    final r = double.parse(v.toDouble().toStringAsFixed(3));
    return r % 1 == 0 ? r.toInt().toString() : r.toString();
  }
}
