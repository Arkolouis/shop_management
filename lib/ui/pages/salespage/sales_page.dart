
import 'package:flutter/material.dart';
import 'package:shop_management/ui/widgets/prodwidgets/product_grid.dart';
import 'package:shop_management/features/cart/cart_panel.dart';

class SalesBody extends StatefulWidget {
  const SalesBody({super.key});

  @override
  State<SalesBody> createState() => _SalesBodyState();
}

class _SalesBodyState extends State<SalesBody> {
  final TextEditingController searchController = TextEditingController();
  String query = "";

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      query = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                searchController.clear();
                                query = "";
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              Expanded(child: ProductGrid(searchQuery: query)),
            ],
          ),
        ),

        const SizedBox(
          width: 350,
          child: Card(margin: EdgeInsets.zero, child: CartPanel()),
        ),
      ],
    );
  }
}
