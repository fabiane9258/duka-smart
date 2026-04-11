import 'package:flutter/widgets.dart';

/// English / Kiswahili UI strings (device locale from [MaterialApp.locale]).
class AppStrings {
  AppStrings(this.locale);

  factory AppStrings.of(BuildContext context) {
    return AppStrings(Localizations.localeOf(context));
  }

  final Locale locale;
  bool get _sw => locale.languageCode == 'sw';

  String t(String en, String sw) => _sw ? sw : en;

  // Navigation
  String get navHome => t('Home', 'Nyumbani');
  String get navInventory => t('Inventory', 'Hifadhi');
  String get navSales => t('Sales', 'Mauzo');
  String get salesHistoryTitle =>
      t('Sales history', 'Historia ya mauzo');
  String get navProfile => t('Profile', 'Wasifu');
  String get appTitle => t('DukaSmart', 'DukaSmart');

  // Landing
  String greetingNamed(String name) =>
      t('Hi $name, ready to manage your shop?',
          'Hujambo $name, tayari kusimamia duka lako?');
  String get greetingAnonymous =>
      t('Hi there, ready to manage your shop?',
          'Hujambo, tayari kusimamia duka lako?');
  String get dailySummary => t('Today’s summary', 'Muhtasari wa leo');
  /// Short grid tile titles (2×2 layout).
  String get tileTotalSalesToday =>
      t('Total sales today', 'Jumla ya mauzo leo');
  String get tileExpensesToday =>
      t('Expenses today', 'Matumizi ya leo');
  String get tileProfitToday => t('Profit today', 'Faida ya leo');
  String get tileLowStockItems =>
      t('Low stock items', 'Bidhaa chache stokini');
  String get salesToday => t('Sales today', 'Mauzo ya leo');
  String get salesTodayHint =>
      t('Total from completed sales', 'Jumla kutoka mauzo yaliyokamilika');
  String get expensesToday => t('Expenses today', 'Matumizi ya leo');
  String get expensesTodayHint =>
      t('Recorded for today', 'Yaliyorekodiwa leo');
  String get profitToday => t('Profit today', 'Faida ya leo');
  String get profitTodayHint =>
      t('Sales minus expenses', 'Mauzo badala ya matumizi');
  String get lowStockCount => t('Low stock items', 'Bidhaa chache');
  String get lowStockCountHint => t('At or below 10 units', 'Chini ya au sawa na 10');
  String get detailSalesTitle =>
      t('Today’s sales', 'Mauzo ya leo');
  String get detailSalesBody => t(
        'This is the sum of all completed sale totals recorded for today. Use New sale to add more.',
        'Hii ni jumla ya mauzo yaliyokamilika leo. Tumia Uza mpya kuongeza.',
      );
  String get detailExpensesTitle =>
      t('Today’s expenses', 'Matumizi ya leo');
  String get detailExpensesBody => t(
        'Sum of expenses you logged today with Log expense. They reduce today’s profit.',
        'Jumla ya matumizi uliyorekodi kwa Rekodi matumizi. Yanapunguza faida ya leo.',
      );
  String get detailProfitTitle =>
      t('Today’s profit', 'Faida ya leo');
  String detailProfitBody(String sales, String expenses) => t(
        'Profit = sales ($sales) minus expenses ($expenses) for today.',
        'Faida = mauzo ($sales) badala ya matumizi ($expenses) ya leo.',
      );
  String get detailLowStockTitle =>
      t('Low stock', 'Stoki chini');
  String get detailLowStockBody => t(
        'Products at or below 10 units. Restock soon to avoid running out.',
        'Bidhaa zilizo chini ya au sawa na vitu 10. Ongeza stoki mapema.',
      );
  String get allStockedWell => t(
        'No low-stock items. You’re in good shape.',
        'Hakuna bidhaa chache stokini. Vizuri.',
      );
  String get tapToExpandHint => t(
        'Tap again to close',
        'Gusa tena kufunga',
      );
  String get addProduct => t('Add product', 'Ongeza bidhaa');
  String get needsAttention => t('Needs attention', 'Inahitaji tahadhari');
  String get outOfStock => t('Out of stock', 'Hakuna stoki');
  String get unitsLeft => t('left', 'zimebaki');
  String get moreInInventory =>
      t('more in Inventory', 'zaidi kwenye Hifadhi');
  String get newSale => t('New sale', 'Uza mpya');
  String get reports => t('Reports', 'Ripoti');
  String get addStock => t('Add stock', 'Ongeza stoki');
  String get logExpense => t('Log expense', 'Rekodi matumizi');
  String get lightMode => t('Light', 'Mwanga');
  String get darkMode => t('Dark', 'Giza');

  // Expense dialog
  String get expenseAmount => t('Amount (KSh)', 'Kiasi (KSh)');
  String get expenseNoteOptional =>
      t('Note (optional)', 'Maelezo (si lazima)');
  String get expenseInvalid =>
      t('Enter a valid amount greater than zero.',
          'Weka kiasi halali kinacho zidi sifuri.');
  String get save => t('Save', 'Hifadhi');
  String get cancel => t('Cancel', 'Ghairi');

  // Profile
  String get profileTitle => t('Your shop profile', 'Wasifu wa duka lako');
  String get profileIntro => t(
        'Add your logo, contact details, and language. Stored only on this device.',
        'Weka nembo, mawasiliano, na lugha. Yote kwenye kifaa hiki tu.',
      );
  String get changePhoto => t('Change photo', 'Badilisha picha');
  String get removePhoto => t('Remove photo', 'Ondoa picha');
  String get ownerName => t('Your name', 'Jina lako');
  String get shopName => t('Shop name', 'Jina la duka');
  String get contactPhone => t('Phone', 'Simu');
  String get contactEmail => t('Email', 'Barua pepe');
  String get businessDetails => t('Business details', 'Maelezo ya biashara');
  String get businessDetailsHint => t(
        'e.g. location, hours, tax notes…',
        'mf. mahali, masaa, kumbukumbu za kodi…',
      );
  String get language => t('Language', 'Lugha');
  String get langEnglish => t('English', 'Kiingereza');
  String get langSwahili => t('Swahili', 'Kiswahili');
  String get saveProfile => t('Save profile', 'Hifadhi wasifu');
  String get profileSaved => t('Profile saved', 'Wasifu umehifadhiwa');
  String get photoWebUnsupported => t(
        'Photo upload is available on mobile and desktop app builds.',
        'Picha inapatikana kwenye simu au programu ya kompyuta.',
      );

  // Inventory
  String get inventoryEmpty => t(
        'No products yet.\nTap Add stock below to add your first item.',
        'Hakuna bidhaa bado.\nGusa Ongeza stoki kuongeza ya kwanza.',
      );
  String get suggestedRestock => t('Suggested restock', 'Mapendekezo ya kununua');
  String get suggestedRestockHint => t(
        'These items are at or below 10 units.',
        'Bidhaa hizi ziko chini ya au sawa na 10.',
      );
  String get stockLabel => t('Stock', 'Stoki');
  String get deleteProductTitle => t('Delete product?', 'Futa bidhaa?');
  String get deleteProductBody => t(
        'This cannot be undone. Past sales history stays unchanged.',
        'Haiwezi kutenduliwa. Historia ya mauzo haibadiliki.',
      );
  String get deleteAction => t('Delete', 'Futa');
  String productRemoved(String name) => t(
        '$name removed from inventory.',
        '$name imeondolewa kwenye hifadhi.',
      );

  // Sales history
  String get noSalesYet =>
      t('No sales recorded yet', 'Hakuna mauzo yaliyorekodiwa');
  String get saleDetails => t('Sale details', 'Maelezo ya mauzo');
  String get noLineItemsInSale => t(
        'No line items for this sale.',
        'Hakuna bidhaa zilizorekodiwa kwenye mauzo haya.',
      );
  String get dateLabel => t('Date', 'Tarehe');

  // Reports
  String get reportsTitle => t('Reports', 'Ripoti');
  String get dateRange => t('Date range', 'Kipindi cha tarehe');
  String get startDate => t('Start', 'Mwanzo');
  String get endDate => t('End', 'Mwisho');
  String get applyRange => t('Apply', 'Tumia');
  String get periodRevenue => t('Sales in period', 'Mauzo katika kipindi');
  String get periodExpenses => t('Expenses in period', 'Matumizi katika kipindi');
  String get periodProfit => t('Profit in period', 'Faida katika kipindi');
  String get topInPeriod => t('Top products (period)', 'Bidhaa bora (kipindi)');
  String get rankedByUnits =>
      t('By units sold in selected dates', 'Kwa vitu vilivouzwa');
  String get noSalesInRange =>
      t('No sales in this date range.', 'Hakuna mauzo katika kipindi hiki.');
  String get retry => t('Retry', 'Jaribu tena');

  // Add product
  String get productName => t('Product name', 'Jina la bidhaa');
  String get priceKsh => t('Price (KSh)', 'Bei (KSh)');
  String get quantity => t('Quantity', 'Idadi');
  String get saveProduct => t('Save product', 'Hifadhi bidhaa');
  String get addProductTitle => t('Add product', 'Ongeza bidhaa');
  String get fillAllFields =>
      t('Please fill all fields.', 'Tafadhali jaza sehemu zote.');
  String get invalidNumbers => t(
        'Enter valid numbers for price and quantity.',
        'Weka nambari halali za bei na idadi.',
      );
  String get productSavedSnack =>
      t('Product saved', 'Bidhaa imehifadhiwa');

  String get cartEmpty => t('Cart is empty', 'Kikapu ni tupu');
  String get payLessThanTotal => t(
        'Amount paid is less than total.',
        'Kiasi kilicholipwa ni kidogo kuliko jumla.',
      );
  String get noProductsForSale => t(
        'No products available. Add stock first.',
        'Hakuna bidhaa. Ongeza stoki kwanza.',
      );
  String checkoutComplete(int soldItems, String changeKes) => t(
        'Checkout complete: $soldItems item(s). Change: $changeKes',
        'Malipo yamekamilika: vitu $soldItems. Rudishi: $changeKes',
      );
  String saleSavedPartial(int soldItems) => t(
        'Sale saved ($soldItems item(s)). Could not refresh inventory — reopen if stock looks wrong.',
        'Mauzo yamehifadhiwa ($soldItems). Stoki haijasasishwa — fungua tena ukiona tatizo.',
      );
  String get notEnoughStock => t(
        'Not enough stock for',
        'Stoki haitoshi kwa',
      );
  String get totalBillLabel => t('Total bill', 'Jumla ya bili');

  // New sale
  String get newSalePos => t('New sale', 'Uza mpya');
  String get amountPaid => t('Amount paid (KSh)', 'Kiasi kilicholipwa (KSh)');
  String get changeLabel => t('Change', 'Rudishi');
  String get totalShort => t('Total', 'Jumla');
  String get paidShort => t('Paid', 'Imelipwa');
  String get balanceDue => t('Balance due', 'Salio linalobaki');
  String get checkout => t('Checkout', 'Maliza');
}
