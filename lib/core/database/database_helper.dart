import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

/// Pengelola database SQLite lokal (singleton).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<String> get databasePath async =>
      p.join(await getDatabasesPath(), AppConstants.dbName);

  Future<Database> _open() async {
    return openDatabase(
      await databasePath,
      version: AppConstants.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static const defaultProducts = <List<Object>>[
    ['Bakso Isi Daging', 'Bakso', 13000, 7000],
    ['Bakso Urat', 'Bakso', 13000, 7000],
    ['Bakso Double', 'Bakso', 20000, 11000],
    ['Bakso Halus', 'Bakso', 10000, 5500],
    ['Mie Ayam', 'Mie Ayam', 12000, 6000],
    ['Mie Ayam Bakso Kecil', 'Mie Ayam', 15000, 8000],
    ['Mie Ayam Bakso Isi Daging', 'Mie Ayam', 20000, 11000],
    ['Mie Ayam Bakso Urat', 'Mie Ayam', 20000, 11000],
  ];

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL DEFAULT 'admin',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');

    batch.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        selling_price INTEGER NOT NULL CHECK (selling_price >= 0),
        cost_price INTEGER NOT NULL DEFAULT 0 CHECK (cost_price >= 0),
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');

    batch.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');

    batch.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        transaction_date TEXT NOT NULL,
        order_type TEXT NOT NULL,
        subtotal INTEGER NOT NULL,
        discount INTEGER NOT NULL DEFAULT 0,
        total INTEGER NOT NULL,
        total_cost INTEGER NOT NULL,
        profit INTEGER NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
      )''');

    batch.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        price INTEGER NOT NULL,
        cost_price INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        cost_total INTEGER NOT NULL,
        profit INTEGER NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )''');

    batch.execute('''
      CREATE TABLE raw_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        unit TEXT NOT NULL,
        stock REAL NOT NULL DEFAULT 0,
        minimum_stock REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');

    batch.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_number TEXT NOT NULL UNIQUE,
        supplier TEXT,
        purchase_date TEXT NOT NULL,
        total INTEGER NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');

    batch.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        raw_material_id INTEGER NOT NULL,
        quantity REAL NOT NULL CHECK (quantity > 0),
        price INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
        FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id)
      )''');

    batch.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK (amount >= 0),
        expense_date TEXT NOT NULL,
        notes TEXT
      )''');

    batch.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        order_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Baru',
        order_type TEXT NOT NULL,
        total INTEGER NOT NULL,
        address TEXT,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
      )''');

    batch.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        price INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )''');

    // Index
    batch.execute('CREATE INDEX idx_customers_name ON customers(name)');
    batch.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    batch.execute('CREATE INDEX idx_sales_date ON sales(transaction_date)');
    batch.execute('CREATE INDEX idx_sales_customer ON sales(customer_id)');
    batch.execute('CREATE INDEX idx_sale_items_sale ON sale_items(sale_id)');
    batch.execute(
        'CREATE INDEX idx_sale_items_product ON sale_items(product_id)');
    batch.execute('CREATE INDEX idx_purchases_date ON purchases(purchase_date)');
    batch.execute(
        'CREATE INDEX idx_purchase_items_purchase ON purchase_items(purchase_id)');
    batch.execute('CREATE INDEX idx_expenses_date ON expenses(expense_date)');
    batch.execute('CREATE INDEX idx_orders_date ON orders(order_date)');
    batch.execute('CREATE INDEX idx_orders_customer ON orders(customer_id)');
    batch.execute('CREATE INDEX idx_order_items_order ON order_items(order_id)');

    // Produk default
    final now = DateTime.now().toIso8601String();
    for (final p in defaultProducts) {
      batch.insert('products', {
        'name': p[0],
        'category': p[1],
        'selling_price': p[2],
        'cost_price': p[3],
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
    }

    await batch.commit(noResult: true);
  }
}
