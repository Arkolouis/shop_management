import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/auth_controller.dart';
import 'package:shop_management/ui/pages/admin/admin_user_page.dart';
import 'package:shop_management/ui/pages/orders/orders_page.dart';
import 'package:shop_management/ui/pages/product/products_page.dart';
import 'package:shop_management/ui/pages/dashboard/dashboard_page.dart';
import 'package:shop_management/ui/pages/login/login_page.dart';
import 'package:shop_management/ui/pages/reports/reports_page.dart';
import 'package:shop_management/ui/pages/salespage/sales_page.dart';
import 'package:shop_management/ui/shell/app_shell.dart';

GoRouter createRouter(AuthController authController) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authController,

    redirect: (context, state) {
      final auth = context.read<AuthController>();
      final user = auth.user;
      final role = auth.role;
      final roleLoading = auth.roleLoading;
      final location = state.uri.toString();
      final isLogin = location == '/';

      if (user == null) return isLogin ? null : '/';
      if (roleLoading) return isLogin ? null : '/';
      if (role == null) return isLogin ? null : '/';
      if (isLogin) return '/dashboard';

      if (location == '/products' && role == 'staff') {
        return '/dashboard';
      }
      if (location == '/reports' && role == 'staff') {
        return '/dashboard';
      }
      if (location == '/admin-users' && role != 'admin' && role != 'manager') {
        return '/dashboard';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/', builder: (context, state) => LoginPage()),

      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            AppShell(currentRoute: '/dashboard', child: const DashboardBody()),
      ),

      GoRoute(
        path: '/products',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'];
          return AppShell(
            currentRoute: '/products',
            child: ProductsPage(showLowStockOnly: filter == 'lowstock'),
          );
        },
      ),
      // GoRoute(
      //   path: '/orders',
      //   builder: (context, state) =>
      //       AppShell(currentRoute: '/orders', child: const OrdersPage()),
      // ),
      GoRoute(
        path: '/sales',
        builder: (context, state) =>
            AppShell(currentRoute: '/sales', child: const SalesBody()),
      ),

      GoRoute(
        path: '/reports',
        builder: (context, state) =>
            AppShell(currentRoute: '/reports', child: const ReportsBody()),
      ),

      GoRoute(
        path: '/admin-users',
        builder: (context, state) => AppShell(
          currentRoute: '/admin-users',
          child: const AdminUsersBody(),
        ),
      ),
    ],
  );
}
