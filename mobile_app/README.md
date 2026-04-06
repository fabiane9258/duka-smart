# DukaSmart Mobile App

Offline-first POS and inventory management system for small retail shops.

## Tech Stack
- **Frontend**: Flutter 3.41.6
- **Database**: SQLite (local), PostgreSQL (backend)
- **Backend**: Django
- **Language**: Dart

## Features
- ✅ Add and manage products
- ✅ Inventory tracking
- ✅ Sales tracking (in development)
- ✅ Expense tracking (in development)
- ✅ Offline support with SQLite

## Project Structure
```
mobile_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   │   └── product.dart
│   ├── screens/               # UI screens
│   │   ├── home_screen.dart
│   │   ├── add_product_screen.dart
│   │   └── product_list_screen.dart
│   ├── database/              # Database logic
│   │   └── database_helper.dart
│   └── widgets/               # Reusable widgets
├── pubspec.yaml               # Dependencies
└── README.md
```

## Getting Started

### Prerequisites
- Flutter 3.41.6+
- Dart 3.11.4+
- Linux, macOS, or Windows

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
**Linux:**
```bash
flutter run -d linux
```

**Web:**
```bash
flutter run -d web
```

**iOS/Android:**
```bash
flutter run
```

## Usage

### Adding a Product
1. Go to **Add Product** from the home screen
2. Enter product details:
   - **Product Name**: Name of the item (e.g., "Apple")
   - **Price**: Numeric value (e.g., "1.50")
   - **Quantity**: Numeric value (e.g., "10")
3. Tap **Save Product**
4. You'll see a confirmation message: "Product Saved"

### Viewing Inventory
1. Go to **Inventory** from the home screen
2. Pull down to refresh the product list
3. View all added products with their price and stock information

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