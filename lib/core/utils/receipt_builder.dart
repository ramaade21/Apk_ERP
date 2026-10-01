import '../../models/sale.dart';
import 'formatters.dart';

/// Membuat teks struk untuk dibagikan (WhatsApp, dsb).
/// Struk hanya berisi info untuk customer: tidak memuat HPP maupun laba.
class ReceiptBuilder {
  static String build(Sale sale, List<SaleItem> items,
      {String shopName = 'Bakso Mie Ayam'}) {
    const line = '--------------------------------';
    final b = StringBuffer()
      ..writeln('*$shopName*')
      ..writeln('No: ${sale.invoiceNumber}')
      ..writeln('Tanggal: ${Fmt.dateTime(sale.date)}')
      ..writeln('Customer: ${sale.customerName ?? 'Umum'}')
      ..writeln('Jenis: ${sale.orderType}')
      ..writeln(line);
    for (final it in items) {
      b.writeln('${it.productName} x${it.quantity}  ${Fmt.rupiah(it.subtotal)}');
    }
    b.writeln(line);
    b.writeln('Subtotal: ${Fmt.rupiah(sale.subtotal)}');
    if (sale.discount > 0) b.writeln('Diskon: ${Fmt.rupiah(sale.discount)}');
    b
      ..writeln('*TOTAL: ${Fmt.rupiah(sale.total)}*')
      ..writeln()
      ..write('Terima kasih!');
    return b.toString();
  }
}
