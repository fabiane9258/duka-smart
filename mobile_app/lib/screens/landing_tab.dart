import 'package:flutter/material.dart';

import '../constants/stock_thresholds.dart';
import '../database/database_helper.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/profile_store.dart';
import '../utils/currency.dart';
import 'add_product_screen.dart';
import 'new_sale_screen.dart';
import 'reports_screen.dart';

enum _SummaryKind { none, sales, expenses, profit, lowStock }

class LandingTab extends StatefulWidget {
  const LandingTab({super.key});

  @override
  State<LandingTab> createState() => LandingTabState();
}

class LandingTabState extends State<LandingTab> {
  String? _shopkeeperName;
  double _todaySales = 0;
  double _todayExpenses = 0;
  List<Product> _alertProducts = [];
  bool _loading = true;
  _SummaryKind _open = _SummaryKind.none;

  @override
  void initState() {
    super.initState();
    loadOverview();
  }

  Future<void> loadOverview() async {
    setState(() => _loading = true);
    try {
      final name = await ProfileStore.ownerDisplayName();
      final today = DateTime.now();
      final revenue =
          await DatabaseHelper.instance.getRevenueForLocalDay(today);
      final expenses =
          await DatabaseHelper.instance.getTotalExpensesForLocalDay(today);
      final products = await DatabaseHelper.instance.getProducts();
      final alerts = products
          .where((p) => p.quantity <= kLowStockMaxUnits)
          .toList()
        ..sort((a, b) => a.quantity.compareTo(b.quantity));
      if (!mounted) return;
      setState(() {
        _shopkeeperName = name;
        _todaySales = revenue;
        _todayExpenses = expenses;
        _alertProducts = alerts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  String _greeting(AppStrings s) {
    final n = _shopkeeperName;
    if (n == null || n.isEmpty) return s.greetingAnonymous;
    return s.greetingNamed(n);
  }

  double get _profitToday => _todaySales - _todayExpenses;

  void _toggleSummary(_SummaryKind kind) {
    setState(() {
      _open = _open == kind ? _SummaryKind.none : kind;
    });
  }

  Future<void> _showLogExpense() async {
    final s = AppStrings.of(context);
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.logExpense,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: s.expenseAmount,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: s.expenseNoteOptional,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final v = double.tryParse(amountCtrl.text.trim());
                  if (v == null || v <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(s.expenseInvalid)),
                    );
                    return;
                  }
                  await DatabaseHelper.instance.insertExpense(
                    amount: v,
                    note: noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  loadOverview();
                },
                child: Text(s.save),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel),
              ),
            ],
          ),
        );
      },
    );
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  Widget _detailPanel(AppStrings s, ThemeData theme) {
    if (_open == _SummaryKind.none) {
      return const SizedBox.shrink();
    }
    final scheme = theme.colorScheme;
    final String title;
    final String body;
    switch (_open) {
      case _SummaryKind.sales:
        title = s.detailSalesTitle;
        body =
            '${s.detailSalesBody}\n\n${formatKes(_todaySales)}\n\n${s.tapToExpandHint}';
        break;
      case _SummaryKind.expenses:
        title = s.detailExpensesTitle;
        body =
            '${s.detailExpensesBody}\n\n${formatKes(_todayExpenses)}\n\n${s.tapToExpandHint}';
        break;
      case _SummaryKind.profit:
        title = s.detailProfitTitle;
        body =
            '${s.detailProfitBody(formatKes(_todaySales), formatKes(_todayExpenses))}\n\n${formatKes(_profitToday)}\n\n${s.tapToExpandHint}';
        break;
      case _SummaryKind.lowStock:
        title = s.detailLowStockTitle;
        final buf = StringBuffer(s.detailLowStockBody);
        buf.writeln();
        if (_alertProducts.isEmpty) {
          buf.writeln(s.allStockedWell);
        } else {
          buf.writeln();
          for (final p in _alertProducts) {
            buf.writeln(
              '• ${p.name} — ${p.quantity == 0 ? s.outOfStock : '${p.quantity} ${s.unitsLeft}'}',
            );
          }
        }
        buf.writeln('\n${s.tapToExpandHint}');
        body = buf.toString();
        break;
      case _SummaryKind.none:
        title = '';
        body = '';
    }
    return Material(
      color: scheme.surfaceContainerHighest.withOpacity(0.45),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = AppStrings.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = constraints.maxWidth > 720 ? 24.0 : 14.0;
        final innerW = (constraints.maxWidth - pad * 2).clamp(0.0, 560.0);
        final cellW = (innerW - 8) / 2;
        final tileAspect = (cellW / 70).clamp(1.85, 3.2);

        return RefreshIndicator(
          onRefresh: loadOverview,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 4, pad, 8),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: innerW,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                              Text(
                                _greeting(s),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: tileAspect,
                                children: [
                                  _SummaryTile(
                                    selected: _open == _SummaryKind.sales,
                                    label: s.tileTotalSalesToday,
                                    value: formatKes(_todaySales),
                                    icon: Icons.trending_up_rounded,
                                    accent: scheme.primary,
                                    onTap: () =>
                                        _toggleSummary(_SummaryKind.sales),
                                  ),
                                  _SummaryTile(
                                    selected: _open == _SummaryKind.expenses,
                                    label: s.tileExpensesToday,
                                    value: formatKes(_todayExpenses),
                                    icon: Icons.receipt_long_outlined,
                                    accent: scheme.tertiary,
                                    onTap: () =>
                                        _toggleSummary(_SummaryKind.expenses),
                                  ),
                                  _SummaryTile(
                                    selected: _open == _SummaryKind.profit,
                                    label: s.tileProfitToday,
                                    value: formatKes(_profitToday),
                                    icon: Icons.savings_outlined,
                                    accent: _profitToday >= 0
                                        ? const Color(0xFF059669)
                                        : scheme.error,
                                    onTap: () =>
                                        _toggleSummary(_SummaryKind.profit),
                                  ),
                                  _SummaryTile(
                                    selected: _open == _SummaryKind.lowStock,
                                    label: s.tileLowStockItems,
                                    value: '${_alertProducts.length}',
                                    icon: Icons.warning_amber_rounded,
                                    accent: _alertProducts.isEmpty
                                        ? scheme.onSurfaceVariant
                                        : const Color(0xFFB45309),
                                    onTap: () =>
                                        _toggleSummary(_SummaryKind.lowStock),
                                  ),
                                ],
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                alignment: Alignment.topCenter,
                                child: _open == _SummaryKind.none
                                    ? const SizedBox(width: double.infinity)
                                    : Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8,
                                        ),
                                        child: _detailPanel(s, theme),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.needsAttention,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 88),
                                child: Scrollbar(
                                  thumbVisibility: _alertProducts.length > 3,
                                  child: ListView(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    children: [
                                      if (_alertProducts.isEmpty)
                                        Text(
                                          s.allStockedWell,
                                          style: theme.textTheme.bodySmall,
                                        )
                                      else
                                        ..._alertProducts.map(
                                          (p) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  p.quantity == 0
                                                      ? Icons
                                                          .remove_shopping_cart_outlined
                                                      : Icons
                                                          .inventory_2_outlined,
                                                  size: 16,
                                                  color: scheme.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    p.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme.bodySmall,
                                                  ),
                                                ),
                                                Text(
                                                  p.quantity == 0
                                                      ? s.outOfStock
                                                      : '${p.quantity}',
                                                  style: theme
                                                      .textTheme.labelMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                ),
                                onPressed: _showLogExpense,
                                icon: const Icon(Icons.add_card_outlined, size: 20),
                                label: Text(s.logExpense),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                onPressed: () async {
                                  await Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          const NewSaleScreen(),
                                    ),
                                  );
                                  loadOverview();
                                },
                                icon: const Icon(Icons.point_of_sale_rounded),
                                label: Text(s.newSale),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize:
                                            const Size.fromHeight(46),
                                      ),
                                      onPressed: () async {
                                        await Navigator.push<void>(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (context) =>
                                                const ReportsScreen(),
                                          ),
                                        );
                                        loadOverview();
                                      },
                                      icon: const Icon(
                                        Icons.insights_outlined,
                                        size: 20,
                                      ),
                                      label: Text(s.reports),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize:
                                            const Size.fromHeight(46),
                                      ),
                                      onPressed: () async {
                                        await Navigator.push<void>(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (context) =>
                                                const AddProductScreen(),
                                          ),
                                        );
                                        loadOverview();
                                      },
                                      icon: const Icon(
                                        Icons.add_box_outlined,
                                        size: 20,
                                      ),
                                      label: Text(s.addProduct),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    ),
                  ),
                ),
              ),
            ),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.selected,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withOpacity(0.55)
          : scheme.surfaceContainerHighest.withOpacity(0.28),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: accent),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.expand_less, size: 16, color: scheme.primary),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  height: 1.1,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
