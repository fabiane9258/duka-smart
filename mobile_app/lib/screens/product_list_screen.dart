import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {

  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await DatabaseHelper.instance.getProducts();

    setState(() {
      products = data;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
      ),

      body: RefreshIndicator(
        onRefresh: loadProducts,

        child: products.isEmpty
            ? const Center(
                child: Text(
                  "No Products Added",
                  style: TextStyle(fontSize: 18),
                ),
              )

            : ListView.builder(
                itemCount: products.length,

                itemBuilder: (context, index) {

                  final product = products[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    child: ListTile(
                      leading: const Icon(Icons.inventory),

                      title: Text(product.name),

                      subtitle: Text(
                        "Price: ${product.price} | Stock: ${product.quantity}",
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}