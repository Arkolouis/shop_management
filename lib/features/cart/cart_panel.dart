import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/sales_controller.dart';
import 'package:shop_management/ui/pages/reciept/reciept_page.dart';

class CartPanel extends StatefulWidget {
  const CartPanel({super.key});

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SalesController>(context);

    return Column(
      children: [
        const SizedBox(height: 10),
        const Text("Cart", style: TextStyle(fontSize: 20)),
        Expanded(
          child: ListView.builder(
            itemCount: controller.cart.length,
            itemBuilder: (context, index) {
              final item = controller.cart[index];

              return ListTile(
                title: Text(item.name),
                subtitle: Text("₵${item.price} x ${item.quantity}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => controller.decreaseQty(item.id),
                    ),
                    Text(item.quantity.toString()),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: item.quantity < item.stock
                          ? () => controller.increaseQty(item.id)
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Text("Total: GHS ${controller.total.toStringAsFixed(2)}"),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: controller.isProcessing
              ? null
              : () async {
                  try {
                    final receipt = await controller.checkout();

                    if (!context.mounted) return;

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiptPage(receipt: receipt),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
          child: controller.isProcessing
              ? const CircularProgressIndicator()
              : const Text("Checkout"),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
