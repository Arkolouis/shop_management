import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/auth_controller.dart';
import 'package:shop_management/controllers/dashboard_controller.dart';
import 'package:shop_management/core/utils/formatters.dart';
import 'package:shop_management/ui/pages/dashboard/staff_dashboard_page.dart';

class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  int _selectedPeriod = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final dash = context.read<DashboardController>();
      if (auth.user != null && !dash.isInitialized) {
        dash.startListening();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardController>();
    final auth = context.watch<AuthController>();
    final role = auth.role ?? '';

    if (dashboard.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardController>().refresh(),
      child: _buildRoleUI(role, dashboard),
    );
  }

  // ✅ keep all your existing _adminManagerDashboard,
  // _staffDashboard, _card, _periodTab etc exactly as they are
  // just remove the Scaffold wrapper
  Widget _buildRoleUI(String role, DashboardController c) {
    switch (role) {
      case "admin":
      case "manager":
        return _adminManagerDashboard(c);
      case "staff":
        return const StaffDashboardPage();
      default:
        return const Center(child: Text("No role assigned"));
    }
  }

  Widget _adminManagerDashboard(DashboardController c) {
    final sales = [
      c.todaySales,
      c.weeklySales,
      c.monthlySales,
      c.yearlySales,
      c.monthlySales,
      c.yearlySales,
    ][_selectedPeriod];

    final transactions = [
      c.totalSalesToday,
      c.weeklyTransactions,
      c.monthlyTransactions,
      c.yearlyTransactions,
      c.weeklyTransactions,
      c.yearlyTransactions,
    ][_selectedPeriod];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _periodTab("Today", 0),
                _periodTab("Weekly", 1),
                _periodTab("Monthly", 2),
                _periodTab("Yearly", 3),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _card(
                "Total Sales",
                formatMoney(sales),
                Icons.attach_money,
                Colors.green,
              ),
              _card(
                "Transactions",
                "$transactions",
                Icons.receipt_long,
                Colors.blue,
              ),
              _card(
                "Products",
                "${c.totalProducts}",
                Icons.inventory_2,
                Colors.indigo,
              ),
              _card(
                "Low Stock",
                "${c.lowStock}",
                Icons.warning_amber,
                c.lowStock > 0 ? Colors.red : Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (c.lowStock > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "${c.lowStock} product${c.lowStock > 1 ? 's are' : ' is'} running low",
                    style: const TextStyle(color: Colors.red),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/products?filter=lowstock'),

                    child: const Text("View"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (c.topProducts.isNotEmpty) ...[
            const Text(
              "Most Patronised Products",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Based on this week's sales",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...c.topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return _productRankTile(
                rank: index + 1,
                name: product.key,
                qty: product.value,
                color: Colors.green,
                isTop: true,
              );
            }),
            const SizedBox(height: 24),
          ],

          if (c.leastProducts.isNotEmpty) ...[
            const Text(
              "Least Patronised Products",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Based on this week's sales",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...c.leastProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return _productRankTile(
                rank: index + 1,
                name: product.key,
                qty: product.value,
                color: Colors.red,
                isTop: false,
              );
            }),
            const SizedBox(height: 24),
          ],

          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go('/reports'),
                icon: const Icon(Icons.bar_chart),
                label: const Text("View Reports"),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/products'),
                icon: const Icon(Icons.inventory_2),
                label: const Text("Manage Products"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodTab(String label, int index) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _productRankTile({
    required int rank,
    required String name,
    required int qty,
    required Color color,
    required bool isTop,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          // rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank == 1 && isTop
                  ? Colors.amber
                  : color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$rank",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank == 1 && isTop ? Colors.white : color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$qty sold",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
}
