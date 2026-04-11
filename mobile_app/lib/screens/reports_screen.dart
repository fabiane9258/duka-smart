import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../l10n/app_strings.dart';
import '../models/product_sales_stats.dart';
import '../utils/currency.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  double _periodRevenue = 0;
  double _periodExpenses = 0;
  List<ProductSalesStats> _topProducts = [];
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeEnd = DateTime(now.year, now.month, now.day);
    _rangeStart = _rangeEnd.subtract(const Duration(days: 29));
    loadReports();
  }

  Future<void> _pickStart() async {
    final s = AppStrings.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart,
      firstDate: DateTime(2020),
      lastDate: _rangeEnd,
      helpText: s.startDate,
    );
    if (picked != null) {
      setState(() => _rangeStart = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickEnd() async {
    final s = AppStrings.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEnd,
      firstDate: _rangeStart,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: s.endDate,
    );
    if (picked != null) {
      setState(() => _rangeEnd = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> loadReports() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      if (_rangeEnd.isBefore(_rangeStart)) {
        setState(() {
          _rangeEnd = _rangeStart;
        });
      }
      final results = await Future.wait([
        DatabaseHelper.instance.getRevenueBetweenLocalDays(
          _rangeStart,
          _rangeEnd,
        ),
        DatabaseHelper.instance.getTotalExpensesBetweenLocalDays(
          _rangeStart,
          _rangeEnd,
        ),
        DatabaseHelper.instance.getTopSellingProductsInLocalDayRange(
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          limit: 10,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _periodRevenue = results[0] as double;
        _periodExpenses = results[1] as double;
        _topProducts = results[2] as List<ProductSalesStats>;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  double get _profit => _periodRevenue - _periodExpenses;

  String _money(double value) => formatKes(value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.reportsTitle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          loadError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loadReports,
                          child: Text(s.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadReports,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        s.dateRange,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickStart,
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(
                                '${s.startDate}: ${_rangeStart.year}-${_rangeStart.month.toString().padLeft(2, '0')}-${_rangeStart.day.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickEnd,
                              icon: const Icon(Icons.event_outlined),
                              label: Text(
                                '${s.endDate}: ${_rangeEnd.year}-${_rangeEnd.month.toString().padLeft(2, '0')}-${_rangeEnd.day.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: loadReports,
                        child: Text(s.applyRange),
                      ),
                      const SizedBox(height: 24),
                      _MetricCard(
                        icon: Icons.trending_up_rounded,
                        iconColor: theme.colorScheme.primary,
                        question: s.periodRevenue,
                        value: _money(_periodRevenue),
                        caption: '',
                      ),
                      const SizedBox(height: 10),
                      _MetricCard(
                        icon: Icons.receipt_long_outlined,
                        iconColor: theme.colorScheme.tertiary,
                        question: s.periodExpenses,
                        value: _money(_periodExpenses),
                        caption: '',
                      ),
                      const SizedBox(height: 10),
                      _MetricCard(
                        icon: Icons.savings_outlined,
                        iconColor: _profit >= 0
                            ? const Color(0xFF059669)
                            : theme.colorScheme.error,
                        question: s.periodProfit,
                        value: _money(_profit),
                        caption: '',
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_outlined,
                            color: theme.colorScheme.secondary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.topInPeriod,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.rankedByUnits,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_topProducts.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              s.noSalesInRange,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._topProducts.asMap().entries.map((entry) {
                          final rank = entry.key + 1;
                          final p = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: rank <= 3
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                foregroundColor: rank <= 3
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                                child: Text('$rank'),
                              ),
                              title: Text(
                                p.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${p.unitsSold} · ${_money(p.revenue)}',
                              ),
                              trailing: rank == 1
                                  ? Icon(
                                      Icons.emoji_events_outlined,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.question,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color iconColor;
  final String question;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: theme.textTheme.titleSmall?.copyWith(
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
