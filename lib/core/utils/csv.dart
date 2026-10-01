/// Utilitas CSV sederhana tanpa dependency.
class Csv {
  /// Satu sel CSV. Teks yang diawali = + - @ diberi tanda petik agar tidak
  /// dieksekusi sebagai rumus oleh Excel/Sheets (CSV injection).
  static String cell(Object? value) {
    if (value == null) return '';
    if (value is num) return value.toString();
    var s = value.toString();
    if (s.isNotEmpty && '=+-@\t\r'.contains(s[0])) s = "'$s";
    if (s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r')) {
      s = '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String encode(List<List<Object?>> rows) =>
      rows.map((r) => r.map(cell).join(',')).join('\r\n');
}
