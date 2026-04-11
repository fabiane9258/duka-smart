import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/expense.dart';
import '../models/product.dart';
import '../models/product_sales_stats.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static final List<Product> _webProducts = [];
  static final List<Sale> _webSales = [];
  static final List<SaleItem> _webSaleItems = [];
  static final List<Expense> _webExpenses = [];

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      // Return a dummy database for web - we use _webProducts instead
      return Future.value(null as Database);
    }
    if (_database != null) return _database!;
    _database = await _initDB('duka_smart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = join(Directory.current.path, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL,
        quantity INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount REAL,
        amount_paid REAL,
        change_amount REAL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER,
        product_id INTEGER,
        product_name TEXT,
        unit_price REAL,
        quantity INTEGER,
        subtotal REAL,
        FOREIGN KEY (sale_id) REFERENCES sales(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          total_amount REAL,
          amount_paid REAL,
          change_amount REAL,
          created_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER,
          product_id INTEGER,
          product_name TEXT,
          unit_price REAL,
          quantity INTEGER,
          subtotal REAL,
          FOREIGN KEY (sale_id) REFERENCES sales(id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future<int> insertProduct(Product product) async {
    if (kIsWeb) {
      final newId = _webProducts.length + 1;
      final newProduct = Product(
        id: newId,
        name: product.name,
        price: product.price,
        quantity: product.quantity,
      );
      _webProducts.add(newProduct);
      return newId;
    }

    final db = await instance.database;
    return db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    if (kIsWeb) {
      // Web implementation: return in-memory products
      return _webProducts;
    }
    
    final db = await instance.database;
    final result = await db.query('products');

    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    if (kIsWeb) {
      // Web implementation: update in-memory product
      final index = _webProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _webProducts[index] = product;
        return 1;
      }
      return 0;
    }

    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> saveSale({
    required List<Product> products,
    required Map<int, int> cart,
    required double totalAmount,
    required double amountPaid,
    required double changeAmount,
  }) async {
    final saleDate = DateTime.now().toIso8601String();

    if (kIsWeb) {
      final saleId = _webSales.length + 1;
      final sale = Sale(
        id: saleId,
        totalAmount: totalAmount,
        amountPaid: amountPaid,
        changeAmount: changeAmount,
        createdAt: saleDate,
      );
      _webSales.add(sale);

      for (final product in products) {
        if (product.id == null) continue;
        final qty = cart[product.id!] ?? 0;
        if (qty == 0) continue;

        final index = _webProducts.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _webProducts[index] = Product(
            id: product.id,
            name: product.name,
            price: product.price,
            quantity: product.quantity - qty,
          );
        }

        _webSaleItems.add(
          SaleItem(
            id: _webSaleItems.length + 1,
            saleId: saleId,
            productId: product.id!,
            productName: product.name,
            unitPrice: product.price,
            quantity: qty,
            subtotal: product.price * qty,
          ),
        );
      }

      return saleId;
    }

    final db = await instance.database;
    return db.transaction<int>((txn) async {
      final saleId = await txn.insert(
        'sales',
        Sale(
          totalAmount: totalAmount,
          amountPaid: amountPaid,
          changeAmount: changeAmount,
          createdAt: saleDate,
        ).toMap(),
      );

      for (final product in products) {
        if (product.id == null) continue;
        final qty = cart[product.id!] ?? 0;
        if (qty == 0) continue;

        await txn.update(
          'products',
          Product(
            id: product.id,
            name: product.name,
            price: product.price,
            quantity: product.quantity - qty,
          ).toMap(),
          where: 'id = ?',
          whereArgs: [product.id],
        );

        await txn.insert(
          'sale_items',
          SaleItem(
            saleId: saleId,
            productId: product.id!,
            productName: product.name,
            unitPrice: product.price,
            quantity: qty,
            subtotal: product.price * qty,
          ).toMap(),
        );
      }

      return saleId;
    });
  }

  Future<List<Sale>> getSales() async {
    if (kIsWeb) {
      final items = [..._webSales];
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    }

    final db = await instance.database;
    final result = await db.query('sales', orderBy: 'created_at DESC');
    return result.map((row) => Sale.fromMap(row)).toList();
  }

  Future<List<SaleItem>> getSaleItemsBySaleId(int saleId) async {
    if (kIsWeb) {
      return _webSaleItems.where((item) => item.saleId == saleId).toList();
    }

    final db = await instance.database;
    final result = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'id ASC',
    );
    return result.map((row) => SaleItem.fromMap(row)).toList();
  }

  /// Inclusive start, exclusive end, in the device's local calendar.
  static (DateTime, DateTime) _localDayBounds(DateTime reference) {
    final local = reference.toLocal();
    final start = DateTime(local.year, local.month, local.day);
    final end = start.add(const Duration(days: 1));
    return (start, end);
  }

  static bool _saleIsInLocalRange(
    Sale sale,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final t = DateTime.tryParse(sale.createdAt)?.toLocal();
    if (t == null) return false;
    return !t.isBefore(rangeStart) && t.isBefore(rangeEnd);
  }

  Future<double> getTotalRevenue() async {
    if (kIsWeb) {
      return _webSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    }
    final db = await instance.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(total_amount), 0) AS t FROM sales',
    );
    return (rows.first['t'] as num).toDouble();
  }

  /// Sum of [Sale.totalAmount] for sales that fall on the same local calendar
  /// day as [day].
  Future<double> getRevenueForLocalDay(DateTime day) async {
    final (start, end) = _localDayBounds(day);
    if (kIsWeb) {
      return _webSales
          .where((s) => _saleIsInLocalRange(s, start, end))
          .fold<double>(0, (sum, s) => sum + s.totalAmount);
    }
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS t
      FROM sales
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (rows.first['t'] as num).toDouble();
  }

  Future<List<ProductSalesStats>> getTopSellingProducts({int limit = 10}) async {
    if (kIsWeb) {
      final map = <int, _Agg>{};
      for (final item in _webSaleItems) {
        map.update(
          item.productId,
          (a) => _Agg(
            productName: item.productName,
            unitsSold: a.unitsSold + item.quantity,
            revenue: a.revenue + item.subtotal,
          ),
          ifAbsent: () => _Agg(
            productName: item.productName,
            unitsSold: item.quantity,
            revenue: item.subtotal,
          ),
        );
      }
      final list = map.entries
          .map(
            (e) => ProductSalesStats(
              productId: e.key,
              productName: e.value.productName,
              unitsSold: e.value.unitsSold,
              revenue: e.value.revenue,
            ),
          )
          .toList()
        ..sort((a, b) => b.unitsSold.compareTo(a.unitsSold));
      if (list.length <= limit) return list;
      return list.sublist(0, limit);
    }

    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT product_id, product_name,
             SUM(quantity) AS total_qty,
             SUM(subtotal) AS total_rev
      FROM sale_items
      GROUP BY product_id, product_name
      ORDER BY total_qty DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows
        .map(
          (row) => ProductSalesStats(
            productId: row['product_id'] as int,
            productName: row['product_name'] as String,
            unitsSold: (row['total_qty'] as num).toInt(),
            revenue: (row['total_rev'] as num).toDouble(),
          ),
        )
        .toList();
  }

  static (DateTime, DateTime) _localCalendarRangeBounds(
    DateTime rangeStartDay,
    DateTime rangeEndDay,
  ) {
    final s = rangeStartDay.toLocal();
    final e = rangeEndDay.toLocal();
    final start = DateTime(s.year, s.month, s.day);
    final endExclusive =
        DateTime(e.year, e.month, e.day).add(const Duration(days: 1));
    return (start, endExclusive);
  }

  static bool _expenseInRange(
    Expense e,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
  ) {
    final t = DateTime.tryParse(e.createdAt)?.toLocal();
    if (t == null) return false;
    return !t.isBefore(rangeStart) && t.isBefore(rangeEndExclusive);
  }

  Future<int> insertExpense({
    required double amount,
    String? note,
    DateTime? at,
  }) async {
    final when = (at ?? DateTime.now()).toIso8601String();
    if (kIsWeb) {
      final id = _webExpenses.length + 1;
      _webExpenses.add(
        Expense(id: id, amount: amount, note: note, createdAt: when),
      );
      return id;
    }
    final db = await instance.database;
    return db.insert(
      'expenses',
      Expense(amount: amount, note: note, createdAt: when).toMap()
        ..remove('id'),
    );
  }

  Future<double> getTotalExpensesForLocalDay(DateTime day) async {
    final (start, end) = _localDayBounds(day);
    if (kIsWeb) {
      return _webExpenses
          .where((e) => _expenseInRange(e, start, end))
          .fold<double>(0, (a, e) => a + e.amount);
    }
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS t
      FROM expenses
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (rows.first['t'] as num).toDouble();
  }

  /// Inclusive calendar [rangeStartDay] through [rangeEndDay] (local).
  Future<double> getRevenueBetweenLocalDays(
    DateTime rangeStartDay,
    DateTime rangeEndDay,
  ) async {
    final (start, endExclusive) =
        _localCalendarRangeBounds(rangeStartDay, rangeEndDay);
    if (kIsWeb) {
      return _webSales
          .where((s) => _saleIsInLocalRange(s, start, endExclusive))
          .fold<double>(0, (a, s) => a + s.totalAmount);
    }
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS t
      FROM sales
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), endExclusive.toIso8601String()],
    );
    return (rows.first['t'] as num).toDouble();
  }

  Future<double> getTotalExpensesBetweenLocalDays(
    DateTime rangeStartDay,
    DateTime rangeEndDay,
  ) async {
    final (start, endExclusive) =
        _localCalendarRangeBounds(rangeStartDay, rangeEndDay);
    if (kIsWeb) {
      return _webExpenses
          .where((e) => _expenseInRange(e, start, endExclusive))
          .fold<double>(0, (a, e) => a + e.amount);
    }
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS t
      FROM expenses
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), endExclusive.toIso8601String()],
    );
    return (rows.first['t'] as num).toDouble();
  }

  Future<List<ProductSalesStats>> getTopSellingProductsInLocalDayRange({
    required DateTime rangeStartDay,
    required DateTime rangeEndDay,
    int limit = 10,
  }) async {
    final (start, endExclusive) =
        _localCalendarRangeBounds(rangeStartDay, rangeEndDay);
    if (kIsWeb) {
      final saleIds = _webSales
          .where((s) => _saleIsInLocalRange(s, start, endExclusive))
          .map((s) => s.id)
          .whereType<int>()
          .toSet();
      final map = <int, _Agg>{};
      for (final item in _webSaleItems) {
        if (!saleIds.contains(item.saleId)) continue;
        map.update(
          item.productId,
          (a) => _Agg(
            productName: item.productName,
            unitsSold: a.unitsSold + item.quantity,
            revenue: a.revenue + item.subtotal,
          ),
          ifAbsent: () => _Agg(
            productName: item.productName,
            unitsSold: item.quantity,
            revenue: item.subtotal,
          ),
        );
      }
      final list = map.entries
          .map(
            (e) => ProductSalesStats(
              productId: e.key,
              productName: e.value.productName,
              unitsSold: e.value.unitsSold,
              revenue: e.value.revenue,
            ),
          )
          .toList()
        ..sort((a, b) => b.unitsSold.compareTo(a.unitsSold));
      if (list.length <= limit) return list;
      return list.sublist(0, limit);
    }

    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT si.product_id, si.product_name,
             SUM(si.quantity) AS total_qty,
             SUM(si.subtotal) AS total_rev
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      WHERE s.created_at >= ? AND s.created_at < ?
      GROUP BY si.product_id, si.product_name
      ORDER BY total_qty DESC
      LIMIT ?
      ''',
      [start.toIso8601String(), endExclusive.toIso8601String(), limit],
    );
    return rows
        .map(
          (row) => ProductSalesStats(
            productId: row['product_id'] as int,
            productName: row['product_name'] as String,
            unitsSold: (row['total_qty'] as num).toInt(),
            revenue: (row['total_rev'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<int> deleteProduct(int id) async {
    if (kIsWeb) {
      _webProducts.removeWhere((p) => p.id == id);
      return 1;
    }
    final db = await instance.database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}

class _Agg {
  final String productName;
  final int unitsSold;
  final double revenue;

  _Agg({
    required this.productName,
    required this.unitsSold,
    required this.revenue,
  });
}