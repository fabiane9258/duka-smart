import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../l10n/app_strings.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../utils/currency.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Sale> sales = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  Future<void> loadSales() async {
    try {
      final data = await DatabaseHelper.instance.getSales();
      if (!mounted) return;
      setState(() {
        sales = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading sales: $e")),
      );
    }
  }

  String formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate)?.toLocal();
    if (dt == null) return isoDate;
    final date =
        "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    final time =
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    return "$date $time";
  }

  Future<void> showSaleDetails(Sale sale) async {
    if (sale.id == null) return;
    final items = await DatabaseHelper.instance.getSaleItemsBySaleId(sale.id!);
    if (!mounted) return;
    final s = AppStrings.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.saleDetails,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text("${s.dateLabel}: ${formatDate(sale.createdAt)}"),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Text(s.noLineItemsInSale)
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text("${item.productName} x${item.quantity}"),
                        ),
                        Text(formatKes(item.subtotal)),
                      ],
                    ),
                  ),
                ),
              const Divider(),
              Text("${s.totalShort}: ${formatKes(sale.totalAmount)}"),
              Text("${s.paidShort}: ${formatKes(sale.amountPaid)}"),
              Text("${s.changeLabel}: ${formatKes(sale.changeAmount)}"),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final body = isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadSales,
              child: sales.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(
                            s.noSalesYet,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: sales.length,
                      itemBuilder: (context, index) {
                        final sale = sales[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(
                              "Sale #${sale.id ?? '-'}",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "${formatDate(sale.createdAt)}\nPaid: ${formatKes(sale.amountPaid)} | Change: ${formatKes(sale.changeAmount)}",
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              formatKes(sale.totalAmount),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => showSaleDetails(sale),
                          ),
                        );
                      },
                    ),
            );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.salesHistoryTitle),
      ),
      body: body,
    );
  }
}
