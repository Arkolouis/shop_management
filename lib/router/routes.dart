import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/auth_controller.dart';
import 'package:shop_management/ui/pages/admin/admin_user_page.dart';
import 'package:shop_management/ui/pages/product/products_page.dart';
import 'package:shop_management/ui/pages/dashboard/dashboard_page.dart';
import 'package:shop_management/ui/pages/login/login_page.dart';
import 'package:shop_management/ui/pages/reports/reports_page.dart';
import 'package:shop_management/ui/pages/salespage/sales_page.dart';

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

      if (user == null) {
        return isLogin ? null : '/';
      }

      if (roleLoading) {
        return isLogin ? null : '/';
      }
      if (role == null) {
        return isLogin ? null : '/';
      }

      if (isLogin) return '/dashboard';

      if (location == '/products' && role == 'staff') {
        return '/dashboard';
      }
      if (location == '/reports' && role == 'staff') {
        return '/dashboard';
      }

      if (location == '/admin-users' && role != 'admin') {
        return '/dashboard';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/', builder: (context, state) => LoginPage()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsPage(),
      ),
      GoRoute(path: '/sales', builder: (context, state) => const SalesPage()),
      GoRoute(
        path: '/admin-users',
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPage(),
      ),
    ],
  );
}
