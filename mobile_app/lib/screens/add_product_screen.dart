import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  void saveProduct() async {
    final s = AppStrings.of(context);
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.fillAllFields)),
      );
      return;
    }

    final price = double.tryParse(priceController.text);
    final quantity = int.tryParse(quantityController.text);

    if (price == null || quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.invalidNumbers)),
      );
      return;
    }

    final product = Product(
      name: nameController.text,
      price: price,
      quantity: quantity,
    );

    try {
      await DatabaseHelper.instance.insertProduct(product);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).productSavedSnack)),
      );

      // Clear form fields for next product
      nameController.clear();
      priceController.clear();
      quantityController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving product: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.addProductTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: s.productName,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: s.priceKsh,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: s.quantity,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saveProduct,
                child: Text(s.saveProduct),
              ),
            ),
          ],
        ),
      ),
    );
  }
}