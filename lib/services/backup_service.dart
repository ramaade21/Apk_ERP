import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import '../core/database/database_helper.dart';

class BackupService {
  final DatabaseHelper _helper;
  BackupService([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  static const _requiredTables = {
    'products',
    'customers',
    'sales',
    'sale_items',
    'raw_materials',
    'purchases',
    'purchase_items',
    'expenses',
    'orders',
    'order_items',
  };

  static String backupFileName(DateTime now) =>
      'backup-bakso-mie-ayam-${DateFormat('yyyyMMdd-HHmmss').format(now)}.db';

  /// Salin database ke folder sementara dan kembalikan file-nya
  /// (siap dibagikan / disimpan pengguna).
  Future<File> createBackup() async {
    await _helper.database; // pastikan database ada
    await _helper.close(); // tutup agar file konsisten saat disalin
    final src = File(await _helper.databasePath);
    final dir = await getTemporaryDirectory();
    final dest = File('${dir.path}/${backupFileName(DateTime.now())}');
    return src.copy(dest.path);
  }

  /// Ganti database dengan file backup. Melempar [FormatException] jika file
  /// bukan backup yang valid.
  Future<void> restoreFrom(String path) async {
    await _validate(path);

    await _helper.close();
    final dbPath = await _helper.databasePath;
    final current = File(dbPath);
    if (await current.exists()) {
      // cadangan pengaman sebelum ditimpa
      await current.copy('$dbPath.before-restore');
    }
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final f = File('$dbPath$suffix');
      if (await f.exists()) await f.delete();
    }
    await File(path).copy(dbPath);
  }

  Future<void> _validate(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const FormatException('File tidak ditemukan');
    }
    final raf = await file.open();
    final header = await raf.read(16);
    await raf.close();
    if (String.fromCharCodes(header) != 'SQLite format 3\u0000') {
      throw const FormatException('File bukan database SQLite');
    }

    Database? db;
    try {
      db = await openDatabase(path, readOnly: true, singleInstance: false);
      final rows = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
      final names = rows.map((r) => r['name'] as String).toSet();
      if (!names.containsAll(_requiredTables)) {
        throw const FormatException('File bukan backup Bakso Mie Ayam');
      }
      final version =
          Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')) ?? 0;
      if (version > AppConstants.dbVersion) {
        throw const FormatException(
            'Backup berasal dari versi aplikasi yang lebih baru');
      }
    } finally {
      await db?.close();
    }
  }
}
