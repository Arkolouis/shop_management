import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/auth_controller.dart';
import 'package:shop_management/controllers/dashboard_controller.dart';
import 'package:shop_management/core/utils/formatters.dart';

class StaffDashboardPage extends StatelessWidget {
  const StaffDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<DashboardController>();
    final auth = context.watch<AuthController>();

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardController>().refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, ${auth.userName ?? 'User'} ",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _todayDate(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/sales'),
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text("Make a Sale"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Today's Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _card(
                  "Today's Sales",
                  formatMoney(c.staffTodaySales),
                  Icons.attach_money,
                  Colors.green,
                ),
                _card(
                  "Transactions",
                  "${c.staffTransactionsToday}",
                  Icons.receipt_long,
                  Colors.blue,
                ),
                _card(
                  "Average Sale",
                  formatMoney(c.staffAverageSaleValue),
                  Icons.calculate,
                  Colors.purple,
                ),
                _card(
                  "Last Sale",
                  formatMoney(c.lastSaleAmount),
                  Icons.access_time,
                  Colors.teal,
                ),
              ],
            ),

            const SizedBox(height: 24),

            _infoCard(
              icon: Icons.trending_up,
              iconColor: Colors.blue,
              bgColor: Colors.blue[50]!,
              borderColor: Colors.blue[200]!,
              label: "Most Sold Today",
              value: c.mostSoldProduct,
            ),

            const SizedBox(height: 12),

            if (c.lastSaleAmount > 0)
              _infoCard(
                icon: Icons.shopping_cart_checkout,
                iconColor: Colors.green,
                bgColor: Colors.green[50]!,
                borderColor: Colors.green[200]!,
                label: "Last Sale",
                value: "${formatMoney(c.lastSaleAmount)} at ${c.lastSaleTime}",
              ),

            const SizedBox(height: 12),

            if (c.lowStockProducts.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Low Stock Alert",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${c.lowStockProducts.length} item${c.lowStockProducts.length > 1 ? 's' : ''}",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...c.lowStockProducts.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(product['name'] as String),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (product['stock'] as num) == 0
                                    ? Colors.red
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (product['stock'] as num) == 0
                                    ? "Out of stock"
                                    : "${product['stock']} left",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _todayDate() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return "${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}";
  }
}
