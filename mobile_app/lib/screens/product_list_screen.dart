import 'package:flutter/material.dart';

import '../constants/stock_thresholds.dart';
import '../database/database_helper.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../utils/currency.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.embedded = false});

  final bool embedded;

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
    if (!mounted) return;
    setState(() {
      products = data;
    });
  }

  List<Product> get _lowStock =>
      products.where((p) => p.quantity <= kLowStockMaxUnits).toList()
        ..sort((a, b) => a.quantity.compareTo(b.quantity));

  List<Product> get _sortedAll {
    final low = products.where((p) => p.quantity <= kLowStockMaxUnits).toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
    final ok = products.where((p) => p.quantity > kLowStockMaxUnits).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [...low, ...ok];
  }

  Future<void> _confirmDelete(Product p) async {
    if (p.id == null) return;
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteProductTitle),
        content: Text(s.deleteProductBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.deleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await DatabaseHelper.instance.deleteProduct(p.id!);
      await loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.productRemoved(p.name))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Widget _content(AppStrings s) {
    final low = _lowStock;
    return RefreshIndicator(
      onRefresh: loadProducts,
      child: products.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    s.inventoryEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: (low.isEmpty ? 0 : 1) + _sortedAll.length,
              itemBuilder: (context, index) {
                if (low.isNotEmpty && index == 0) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Theme.of(context)
                        .colorScheme
                        .tertiaryContainer
                        .withOpacity(0.45),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.suggestedRestock,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.suggestedRestockHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          ...low.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${s.stockLabel}: ${p.quantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: p.quantity == 0
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context)
                                              .colorScheme
                                              .onTertiaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final pi = index - (low.isEmpty ? 0 : 1);
                final product = _sortedAll[pi];
                final isLow = product.quantity <= kLowStockMaxUnits;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isLow
                      ? Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withOpacity(0.25)
                      : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.inventory_2_outlined,
                      color: isLow
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${formatKes(product.price)} · ${s.stockLabel}: ${product.quantity}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: s.deleteAction,
                      onPressed: () => _confirmDelete(product),
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (widget.embedded) {
      return SafeArea(
        child: Stack(
          children: [
            _content(s),
            Positioned(
              left: 16,
              right: 16,
              bottom: 8,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const AddProductScreen(),
                    ),
                  );
                  loadProducts();
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(s.addStock),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navInventory),
      ),
      body: _content(s),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const AddProductScreen(),
            ),
          );
          loadProducts();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addStock),
      ),
    );
  }
}
