# Arsitektur

Lapisan: `screens` (UI) → `providers` (state, ChangeNotifier) → `repositories` (query SQL) → `core/database` (SQLite).

- Semua nominal disimpan sebagai `INTEGER` Rupiah bulat, tanpa desimal.
- Perhitungan penjualan/HPP/laba ada di `core/utils/sale_calculator.dart` (murni Dart, mudah di-test).
- Tanggal disimpan ISO-8601, ditampilkan DD/MM/YYYY dan HH:mm lewat `Fmt`.
- Foreign key aktif (`PRAGMA foreign_keys = ON`).
- Harga dan HPP pada `sale_items` disalin saat transaksi, sehingga perubahan harga produk tidak mengubah laporan lama.

## Tabel

users, products, customers, sales, sale_items, raw_materials, purchases, purchase_items, expenses, orders, order_items.
