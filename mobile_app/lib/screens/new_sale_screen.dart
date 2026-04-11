import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../utils/currency.dart';

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
    final s = AppStrings.of(context);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.cartEmpty)),
      );
      return;
    }

    if (amountPaid < totalBill) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.payLessThanTotal)),
      );
      return;
    }

    for (final product in products) {
      if (product.id == null) continue;
      final qtyInCart = cart[product.id!] ?? 0;
      if (qtyInCart > product.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.notEnoughStock} ${product.name}')),
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
      final msg = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reloaded
                ? msg.checkoutComplete(soldItems, formatKes(change))
                : msg.saleSavedPartial(soldItems),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.newSalePos),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? Center(
                  child: Text(
                    s.noProductsForSale,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
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
                                "${formatKes(product.price)}   ${s.stockLabel}: ${product.quantity}",
                              ),
                              trailing: product.quantity <= 0
                                  ? Text(
                                      s.outOfStock,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
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
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.6),
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "${s.totalBillLabel}: ${formatKes(totalBill)}",
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
                            decoration: InputDecoration(
                              labelText: s.amountPaid,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            balance >= 0
                                ? "${s.changeLabel}: ${formatKes(balance)}"
                                : "${s.balanceDue}: ${formatKes(balance.abs())}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: balance >= 0
                                  ? const Color(0xFF059669)
                                  : theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: FilledButton(
                              onPressed: cart.isEmpty ? null : _checkout,
                              child: Text(s.checkout),
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