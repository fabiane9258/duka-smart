import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static final List<Product> _webProducts = [];
  static final List<Sale> _webSales = [];
  static final List<SaleItem> _webSaleItems = [];

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
      version: 2,
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
}