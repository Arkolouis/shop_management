import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_management/ui/widgets/prodwidgets/product_grid.dart';
import 'package:shop_management/features/cart/cart_panel.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sales",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard') ,
        ),
      ),
      body: Row(
        children: [
          const Expanded(flex: 3, child: ProductGrid()),

          const SizedBox(
            width: 350,
            child: Card(margin: EdgeInsets.zero, child: CartPanel()),
          ),
        ],
      ),
    );
  }
}
