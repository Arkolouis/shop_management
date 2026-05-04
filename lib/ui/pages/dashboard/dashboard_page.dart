import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/auth_controller.dart';
import 'package:shop_management/controllers/dashboard_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
    final role = auth.role;

    if (auth.user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    if (auth.roleLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (role == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("No role assigned to your account."),
              TextButton(
                onPressed: () => context.read<AuthController>().logout(),
                child: const Text("Logout"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          // ✅ live indicator — shows green dot when streams are active
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dashboard.isInitialized
                        ? Colors.green
                        : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  dashboard.isInitialized ? "Live" : "Connecting...",
                  style: TextStyle(
                    color: dashboard.isInitialized
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            // ── Drawer header ──
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.store, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    "Shop Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // ✅ show username if available
                  Text(
                    auth.nameController.text.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    role.toUpperCase(),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () => context.go('/dashboard'),
            ),

            if (role != "staff")
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text("Products"),
                onTap: () => context.go('/products'),
              ),

            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text("Sales"),
              onTap: () => context.go('/sales'),
            ),

            if (role == "admin" || role == "manager")
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text("Reports"),
                onTap: () => context.go('/reports'),
              ),

            if (role == "admin")
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text("User Management"),
                onTap: () => context.go('/admin-users'),
              ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                context.read<DashboardController>().reset();
                await context.read<AuthController>().logout();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardController>().refresh(),
        child: dashboard.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildRoleUI(role, dashboard),
              ),
      ),
    );
  }

  Widget _buildRoleUI(String role, DashboardController c) {
    switch (role) {
      case "admin":
        return _stats(c, showReports: true);
      case "manager":
        return _stats(c, showReports: true);
      case "staff":
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text(
              "Go to Sales",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        );
      default:
        return const Center(child: Text("No role assigned"));
    }
  }

  Widget _stats(DashboardController c, {required bool showReports}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Overview",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              // ✅ last updated time
              Text(
                "Updates automatically",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Stat cards ──
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _card(
                "Today's Sales",
                "₵${c.todaySales.toStringAsFixed(2)}",
                Icons.attach_money,
                Colors.green,
              ),
              _card(
                "Products",
                "${c.totalProducts}",
                Icons.inventory_2,
                Colors.blue,
              ),
              _card(
                "Low Stock",
                "${c.lowStock}",
                Icons.warning_amber,
                // ✅ card turns red if there are low stock items
                c.lowStock > 0 ? Colors.red : Colors.orange,
              ),
              _card(
                "Transactions",
                "${c.totalSalesToday}",
                Icons.receipt,
                Colors.purple,
              ),
            ],
          ),

          // ✅ low stock warning banner
          if (c.lowStock > 0) ...[
            const SizedBox(height: 20),
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
                    "${c.lowStock} product${c.lowStock > 1 ? 's are' : ' is'} running low on stock",
                    style: const TextStyle(color: Colors.red),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/products'),
                    child: const Text("View Products"),
                  ),
                ],
              ),
            ),
          ],

          if (showReports) ...[
            const SizedBox(height: 30),
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.go('/reports'),
              icon: const Icon(Icons.bar_chart),
              label: const Text("View Full Reports"),
            ),
          ],
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
