import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final data = await DatabaseHelper.instance.getProducts();
      setState(() {
        products = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading products: $e")),
      );
    }
  }

  void showSaleDialog(Product product) {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Sell ${product.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Available: ${product.quantity}"),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity to sell",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Sell"),
              onPressed: () async {
                final qty = int.tryParse(qtyController.text);
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a valid quantity")),
                  );
                  return;
                }

                if (qty > product.quantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Not enough stock available")),
                  );
                  return;
                }

                try {
                  // Update product quantity
                  final updatedProduct = Product(
                    id: product.id,
                    name: product.name,
                    price: product.price,
                    quantity: product.quantity - qty,
                  );

                  await DatabaseHelper.instance.updateProduct(updatedProduct);

                  // Refresh product list
                  await loadProducts();

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Sold $qty ${product.name}(s)")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error processing sale: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Sale - POS"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(
                  child: Text(
                    "No products available\nAdd products first",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Price: \$${product.price.toStringAsFixed(2)} | Stock: ${product.quantity}",
                        ),
                        trailing: product.quantity > 0
                            ? ElevatedButton(
                                onPressed: () => showSaleDialog(product),
                                child: const Text("Sell"),
                              )
                            : const Text(
                                "Out of Stock",
                                style: TextStyle(color: Colors.red),
                              ),
                        onTap: product.quantity > 0 ? () => showSaleDialog(product) : null,
                      ),
                    );
                  },
                ),
    );
  }
}