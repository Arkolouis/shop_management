import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/sales_controller.dart';
import 'package:shop_management/core/models/sale_model.dart';
import 'package:shop_management/ui/pages/reciept/reciept_page.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final salesController = context.read<SalesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go("/dashboard"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Sale>>(
          stream: salesController.salesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No sales yet"));
            }

            final sales = snapshot.data!;

            final totalSales = sales.fold(
              0.0,
              (value, sale) => value + sale.total,
            );

            final totalTransactions = sales.length;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildCard(
                        title: "Total Sales",
                        value: "₵${totalSales.toStringAsFixed(2)}",
                        icon: Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCard(
                        title: "Transactions",
                        value: totalTransactions.toString(),
                        icon: Icons.receipt_long,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// 📋 SALES LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.shopping_cart),
                          title: Text("₵${sale.total.toStringAsFixed(2)}"),
                          subtitle: Text(sale.date.toString()),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),

                          /// 🔍 View receipt
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReceiptPage(
                                  receipt: {
                                    'id': sale.id,
                                    'total': sale.total,
                                    'date': sale.date,
                                    'items': sale.items,
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 🔧 Reusable Card
  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
