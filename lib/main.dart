import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/admin_controller.dart';
import 'package:shop_management/controllers/dashboard_controller.dart';
import 'package:shop_management/controllers/auth_controller.dart';
import 'package:shop_management/controllers/product_controller.dart';
import 'package:shop_management/controllers/sales_controller.dart';
import 'package:shop_management/router/routes.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Create AuthController ONCE here
  final authController = AuthController();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController), // ✅ same instance
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => SalesController()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
      ],
      child: ShopApp(authController: authController),
    ),
  );
}

class ShopApp extends StatelessWidget {
  final AuthController authController;
  const ShopApp({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    // ✅ Router gets the exact same instance as Provider
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: createRouter(authController),
    );
  }
}
