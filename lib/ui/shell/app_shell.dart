import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:shop_management/controllers/auth_controller.dart';
import 'package:shop_management/controllers/dashboard_controller.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({super.key, required this.child, required this.currentRoute});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final SidebarXController _sidebarController;

  // ── Route to sidebar index map ──
  final _routes = [
    '/dashboard',
    '/products',
    '/sales',
    '/reports',
    '/admin-users',
  ];

  @override
  void initState() {
    super.initState();
    final index = _routes.indexOf(widget.currentRoute);
    _sidebarController = SidebarXController(
      selectedIndex: index < 0 ? 0 : index,
      extended: true,
    );

    _sidebarController.addListener(() {
      final role = context.read<AuthController>().role ?? '';
      final routes = _getRoutesForRole(role);
      final selected = _sidebarController.selectedIndex;
      if (selected < routes.length) {
        final route = routes[selected];
        if (route != widget.currentRoute) {
          context.go(route);
        }
      }
    });
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      final index = _routes.indexOf(widget.currentRoute);
      if (index >= 0) {
        _sidebarController.selectIndex(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final dashboard = context.watch<DashboardController>();
    final role = auth.role ?? '';
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      drawer: isWide
          ? null
          : Drawer(child: _buildSidebar(role, auth, dashboard)),

      body: Row(
        children: [
          if (isWide) _buildSidebar(role, auth, dashboard),

          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, role, auth, dashboard, isWide),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    String role,
    AuthController auth,
    DashboardController dashboard,
  ) {
    return SidebarX(
      controller: _sidebarController,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // dark blue-grey
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        itemTextPadding: const EdgeInsets.only(left: 8),
        selectedItemTextPadding: const EdgeInsets.only(left: 8),
        itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        selectedItemDecoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
        ),
        iconTheme: const IconThemeData(color: Colors.white54, size: 20),
        selectedIconTheme: const IconThemeData(color: Colors.blue, size: 20),
      ),
      extendedTheme: const SidebarXTheme(
        width: 220,
        decoration: BoxDecoration(color: Color(0xFF1E293B)),
      ),
      headerBuilder: (context, extended) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 28),
              ),

              if (extended) ...[
                const SizedBox(height: 12),
                const Text(
                  "Shop Management",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  auth.userName ?? auth.user?.email ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              const Divider(color: Colors.white12),
            ],
          ),
        );
      },

      footerBuilder: (context, extended) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Divider(color: Colors.white12),
              const SizedBox(height: 4),

              const SizedBox(height: 8),

              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  alignment: Alignment.centerLeft,
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                onPressed: () async {
                  context.read<DashboardController>().reset();
                  await context.read<AuthController>().logout();
                  if (context.mounted) context.go('/');
                },
              ),
            ],
          ),
        );
      },

      items: _buildNavItems(role),
    );
  }

  List<SidebarXItem> _buildNavItems(String role) {
    final items = <SidebarXItem>[
      const SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
      if (role != 'staff')
        const SidebarXItem(icon: Icons.inventory_2, label: 'Products'),
      const SidebarXItem(icon: Icons.point_of_sale, label: 'Sales'),
      if (role == 'admin' || role == 'manager')
        const SidebarXItem(icon: Icons.bar_chart, label: 'Reports'),
      if (role == 'admin' || role == 'manager')
        const SidebarXItem(icon: Icons.people, label: 'User Management'),
    ];
    return items;
  }

  List<String> _getRoutesForRole(String role) {
    return [
      '/dashboard',
      if (role != 'staff') '/products',
      '/sales',
      if (role == 'admin' || role == 'manager') '/reports',
      if (role == 'admin' || role == 'manager') '/admin-users',
    ];
  }

  Widget _buildTopBar(
    BuildContext context,
    String role,
    AuthController auth,
    DashboardController dashboard,
    bool isWide,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isWide)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),

          Text(
            _pageTitle(widget.currentRoute),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const Spacer(),

          PopupMenuButton(
            offset: const Offset(0, 45),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue,
                  child: Text(
                    (auth.userName ?? auth.user?.email ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.userName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'profile',
                child: const Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text("Profile"),
                  ],
                ),
                onTap: () {},
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Logout", style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: () async {
                  context.read<DashboardController>().reset();
                  await context.read<AuthController>().logout();
                  if (context.mounted) context.go('/');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _pageTitle(String route) {
    switch (route) {
      case '/dashboard':
        return 'Dashboard';
      case '/products':
        return 'Products';
      case '/sales':
        return 'Sales';
      case '/reports':
        return 'Reports';
      case '/admin-users':
        return 'User Management';
      default:
        return 'Shop Management';
    }
  }
}
