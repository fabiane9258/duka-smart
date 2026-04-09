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
  final Map<int, int> cart = {};
  final TextEditingController paidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  void dispose() {
    paidController.dispose();
    super.dispose();
  }

  /// Returns true if products were loaded and state was updated; false if
  /// unmounted or an error occurred (error snackbar is shown on failure).
  Future<bool> loadProducts() async {
    try {
      final data = await DatabaseHelper.instance.getProducts();
      if (!mounted) return false;
      setState(() {
        products = data;
        isLoading = false;
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading products: $e")),
      );
      return false;
    }
  }

  int _cartQty(Product product) => cart[product.id ?? -1] ?? 0;

  void _increaseQty(Product product) {
    if (product.id == null || product.quantity <= 0) return;
    final current = _cartQty(product);
    if (current >= product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Only ${product.quantity} ${product.name}(s) in stock")),
      );
      return;
    }
    setState(() {
      cart[product.id!] = current + 1;
    });
  }

  void _decreaseQty(Product product) {
    if (product.id == null) return;
    final current = _cartQty(product);
    if (current <= 0) return;
    setState(() {
      final next = current - 1;
      if (next == 0) {
        cart.remove(product.id!);
      } else {
        cart[product.id!] = next;
      }
    });
  }

  double get totalBill {
    double total = 0;
    for (final product in products) {
      if (product.id == null) continue;
      total += product.price * (cart[product.id!] ?? 0);
    }
    return total;
  }

  double get amountPaid => double.tryParse(paidController.text.trim()) ?? 0;

  double get balance => amountPaid - totalBill;

  Future<void> _checkout() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart is empty")),
      );
      return;
    }

    if (amountPaid < totalBill) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amount paid is less than total bill")),
      );
      return;
    }

    for (final product in products) {
      if (product.id == null) continue;
      final qtyInCart = cart[product.id!] ?? 0;
      if (qtyInCart > product.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Not enough stock for ${product.name}")),
        );
        return;
      }
    }

    try {
      final checkoutCart = Map<int, int>.from(cart);
      await DatabaseHelper.instance.saveSale(
        products: products,
        cart: checkoutCart,
        totalAmount: totalBill,
        amountPaid: amountPaid,
        changeAmount: balance,
      );

      final soldItems = checkoutCart.values.fold<int>(0, (sum, qty) => sum + qty);
      final change = balance;

      // Reload inventory first so we never clear the cart while the list is still stale.
      final reloaded = await loadProducts();
      if (!mounted) return;

      setState(() {
        cart.clear();
        paidController.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reloaded
                ? "Checkout complete: $soldItems item(s). Change: \$${change.toStringAsFixed(2)}"
                : "Sale saved ($soldItems item(s)). Could not refresh inventory — reopen this screen if stock looks wrong.",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during checkout: $e")),
      );
    }
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
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final qty = _cartQty(product);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                product.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                "\$${product.price.toStringAsFixed(2)}   Stock: ${product.quantity}",
                              ),
                              trailing: product.quantity <= 0
                                  ? const Text(
                                      "Out of stock",
                                      style: TextStyle(color: Colors.red),
                                    )
                                  : SizedBox(
                                      width: 128,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            onPressed: () => _decreaseQty(product),
                                            icon: const Icon(Icons.remove_circle_outline),
                                          ),
                                          Text(
                                            "$qty",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _increaseQty(product),
                                            icon: const Icon(Icons.add_circle_outline),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: const Border(
                          top: BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Total Bill: \$${totalBill.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: paidController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: "Amount Paid",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            balance >= 0
                                ? "Change: \$${balance.toStringAsFixed(2)}"
                                : "Balance Due: \$${balance.abs().toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: cart.isEmpty ? null : _checkout,
                              child: const Text("Checkout"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}