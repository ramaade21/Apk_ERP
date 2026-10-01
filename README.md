# Bakso Mie Ayam - Manajemen Penjualan & Laba Rugi

Aplikasi Android offline untuk mencatat penjualan, pesanan, bahan baku, pengeluaran, serta menghitung omzet, HPP, laba kotor, dan laba bersih warung bakso/mie ayam.

![Screenshot Dashboard](docs/screenshots/dashboard.png)
![Screenshot Penjualan](docs/screenshots/penjualan.png)

> Screenshot di atas adalah placeholder. Ganti dengan tangkapan layar asli.

## Status pengembangan

| Fase | Isi | Status |
|------|-----|--------|
| 1 | Setup, SQLite (11 tabel), Produk, Customer | Selesai |
| 2 | Penjualan, Pesanan, omzet/HPP/laba | Selesai |
| 3 | Bahan baku, pembelian, pengeluaran, stok | Selesai |
| 4 | Dashboard, laporan harian/bulanan, grafik | Selesai |
| 5a | Backup/Restore, export CSV, share struk | Selesai |
| 5b | Export PDF dan Excel (.xlsx) | Belum |
| 5c | Data contoh, pengaturan (dark mode) | Belum |
| 6 | Integration test, penyempurnaan | Belum |

## Fitur

Penjualan, pesanan customer, customer management, produk, bahan baku, stok, pembelian, pengeluaran, laba/rugi, laporan harian dan bulanan, export PDF/Excel, backup/restore, offline SQLite.

## Tech stack

Flutter, Dart, SQLite (sqflite), Provider, Material 3, GitHub Actions.

## Instalasi APK

1. Buka tab **Actions** di GitHub, pilih run **Build Android APK** terbaru, unduh artifact `bakso-mie-ayam-apk`, atau unduh dari halaman **Releases**.
2. Ekstrak zip, salin `app-release.apk` ke HP.
3. Izinkan "Install dari sumber tidak dikenal", lalu buka file APK.

## Menjalankan dari source

```bash
# 1. Install Flutter: https://docs.flutter.dev/get-started/install
flutter --version

# 2. Jika folder android/ belum ada, buat platform file (sekali saja)
flutter create --platforms=android --org id.bakso --project-name bakso_mie_ayam .
rm -f test/widget_test.dart

# 3. Dependency
flutter pub get

# 4. Jalankan
flutter run

# 5. Test
flutter analyze
flutter test

# 6. Build APK
flutter build apk --debug
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```

## Upload ke GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<username>/bakso-mie-ayam.git
git push -u origin main
```

## Release APK

```bash
git tag v1.0.0
git push origin v1.0.0
```

Workflow `release-apk.yml` akan membuat GitHub Release dengan file `bakso-mie-ayam-v1.0.0.apk`.

## Catatan keamanan

Jangan commit `.env`, keystore, password, atau API key. Semua sudah ada di `.gitignore`. APK release saat ini ditandatangani dengan debug key; untuk rilis publik buat keystore sendiri dan simpan sebagai GitHub Secrets.

## Lisensi

MIT, lihat [LICENSE](LICENSE).
