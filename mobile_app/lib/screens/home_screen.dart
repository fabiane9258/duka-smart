import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'product_list_screen.dart';
import 'new_sale_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("DukaSmart"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,

          children: [

            DashboardButton(
              title: "New Sale",
              icon: Icons.point_of_sale,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewSaleScreen(),
                  ),
                );
              },
            ),

            DashboardButton(
              title: "Add Product",
              icon: Icons.inventory,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ),
                );
              },
            ),

            DashboardButton(
              title: "Expenses",
              icon: Icons.money_off,
              onTap: () {},
            ),
            
            DashboardButton(
              title: "Inventory",
              icon: Icons.inventory_2,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductListScreen(),
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}

class DashboardButton extends StatelessWidget {

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const DashboardButton({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 4,

      child: InkWell(
        onTap: onTap,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(icon, size: 40),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),

          ],
        ),
      ),
    );
  }
}