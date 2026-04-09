import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static List<Product> _webProducts = []; // In-memory storage for web

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
      version: 1,
      onCreate: _createDB,
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
  }

 Future<int> insertProduct(Product product) async {
  if (kIsWeb) {
    // Web implementation using in-memory storage
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

  print("INSERTING PRODUCT...");
  print(product.name);
  print(product.price);
  print(product.quantity);

  final result = await db.insert('products', product.toMap());

  print("PRODUCT INSERTED ID: $result");

  return result;
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
}