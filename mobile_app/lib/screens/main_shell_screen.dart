import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'landing_tab.dart';
import 'product_list_screen.dart';
import 'profile_screen.dart';
import 'sales_history_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;
  final GlobalKey<LandingTabState> _landingKey = GlobalKey<LandingTabState>();

  String _title(AppStrings s, int i) {
    switch (i) {
      case 0:
        return s.appTitle;
      case 1:
        return s.navInventory;
      case 2:
        return s.navSales;
      default:
        return s.navProfile;
    }
  }

  void _onSelect(int i) {
    setState(() => _index = i);
    if (i == 0) {
      _landingKey.currentState?.loadOverview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;

        final pages = <Widget>[
          LandingTab(key: _landingKey),
          const ProductListScreen(embedded: true),
          const SalesHistoryScreen(embedded: true),
          ProfileScreen(
            embedded: true,
            onProfileSaved: () => _landingKey.currentState?.loadOverview(),
          ),
        ];

        if (wide) {
          final extended = constraints.maxWidth >= 1100;
          final s = AppStrings.of(context);
          final bg = Theme.of(context).scaffoldBackgroundColor;
          return Scaffold(
            backgroundColor: bg,
            body: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  backgroundColor:
                      Theme.of(context).navigationRailTheme.backgroundColor ??
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                  selectedIndex: _index,
                  onDestinationSelected: _onSelect,
                  // When extended is true, labels sit beside icons; Flutter only
                  // allows labelType none (or null) in that mode.
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.selected,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: Text(s.navHome),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.inventory_2_outlined),
                      selectedIcon: const Icon(Icons.inventory_2_rounded),
                      label: Text(s.navInventory),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.receipt_long_outlined),
                      selectedIcon: const Icon(Icons.receipt_long_rounded),
                      label: Text(s.navSales),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline_rounded),
                      selectedIcon: const Icon(Icons.person_rounded),
                      label: Text(s.navProfile),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: bg,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                          child: Text(
                            _title(s, _index),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _index,
                          children: pages,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final s = AppStrings.of(context);
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(_title(s, _index)),
          ),
          body: IndexedStack(
            index: _index,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onSelect,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: s.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.inventory_2_outlined),
                selectedIcon: const Icon(Icons.inventory_2_rounded),
                label: s.navInventory,
              ),
              NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: const Icon(Icons.receipt_long_rounded),
                label: s.navSales,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: s.navProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}
