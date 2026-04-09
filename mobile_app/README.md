# DukaSmart Mobile App

Offline-first POS and inventory management system for small retail shops.

## Tech Stack
- **Frontend**: Flutter 3.41.6
- **Database**: SQLite (desktop), In-memory storage (web), PostgreSQL (backend)
- **Backend**: Django (planned)
- **Language**: Dart
- **Platforms**: Web, Linux, macOS, Windows, Android, iOS

## Features
- ✅ **Product Management**: Add, view, and manage products
- ✅ **Inventory Tracking**: Real-time stock monitoring
- ✅ **Point of Sale (POS)**: Complete sales with automatic stock reduction
- ✅ **Cross-Platform**: Works on web, desktop, and mobile
- ✅ **Offline Support**: Local database with web fallback
- 🔄 **Expense Tracking**: Planned for future release
- 🔄 **Backend Sync**: Django integration planned

## Project Structure
```
mobile_app/
├── lib/
│   ├── main.dart                    # App entry point with platform-specific setup
│   ├── models/                      # Data models
│   │   └── product.dart
│   ├── screens/                     # UI screens
│   │   ├── home_screen.dart         # Main dashboard
│   │   ├── add_product_screen.dart  # Product creation
│   │   ├── product_list_screen.dart # Inventory view
│   │   └── new_sale_screen.dart     # POS interface
│   ├── database/                    # Database logic
│   │   └── database_helper.dart     # Cross-platform database abstraction
│   └── widgets/                     # Reusable widgets
├── pubspec.yaml                     # Dependencies
└── README.md
```

## Getting Started

### Prerequisites
- Flutter 3.41.6+
- Dart 3.11.4+
- Linux, macOS, Windows, or Android SDK (for mobile testing)

### Installation
1. Clone the repository
2. Navigate to the mobile_app directory:
   ```bash
   cd mobile_app
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App
**Web (Recommended for testing):**
```bash
flutter run -d chrome
```

**Linux Desktop:**
```bash
flutter run -d linux
```

**Android Emulator:**
```bash
flutter run -d android
```

**iOS Simulator (macOS only):**
```bash
flutter run -d ios
```

## Usage

### Adding a Product
1. Go to **Add Product** from the home screen
2. Enter product details:
   - **Product Name**: Name of the item (e.g., "Apple")
   - **Price**: Numeric value (e.g., "1.50")
   - **Quantity**: Numeric value (e.g., "10")
3. Tap **Save Product**
4. Form clears automatically for adding multiple products
5. You'll see a confirmation message: "Product Saved"

### Point of Sale (POS)
1. Go to **New Sale** from the home screen
2. View all available products in a list
3. Tap any product to open the sale dialog
4. Enter the quantity to sell
5. Tap **Sell** to complete the transaction
6. Stock automatically reduces in the database
7. Product list updates in real-time

### Viewing Inventory
1. Go to **Inventory** from the home screen
2. View all products with current stock levels
3. Products show "Out of Stock" when quantity reaches zero
4. Pull down to refresh the product list

### Dashboard Features
- **New Sale**: Access POS interface
- **Add Product**: Create new inventory items
- **Inventory**: View all products and stock levels
- **Expenses**: Planned for future release

## Known Issues & Fixes Applied
- ✅ Fixed database initialization for desktop (Linux/Windows/macOS)
- ✅ Added input validation for price and quantity
- ✅ Added error handling and snackbar notifications
- ✅ Integrated sqflite_common_ffi for desktop SQLite support

## Dependencies
- sqflite: ^2.3.0 - SQLite database for Flutter
- sqflite_common_ffi: ^2.3.0 - Desktop SQLite support
- path: ^1.8.3 - Path operations

## Future Enhancements
- Complete sales tracking
- Expense management
- Backend synchronization with Django
- Cloud backup features
- Product categories
- Search and filter products

## Development Notes
- Database is stored locally in the project directory
- All data persists offline
- Built with responsive UI using MaterialApp theme (Green)
- Uses state management with StatefulWidgets

## License
All rights reserved