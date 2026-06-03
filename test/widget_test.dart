import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/auth_controller.dart';
import 'package:shop_management/controllers/dashboard_controller.dart';
import 'package:shop_management/controllers/product_controller.dart';
import 'package:shop_management/controllers/sales_controller.dart';
import 'package:shop_management/main.dart';

void main() {
  testWidgets('App renders login page on launch', (WidgetTester tester) async {
    final authController = AuthController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          ChangeNotifierProvider(create: (_) => DashboardController()),
          ChangeNotifierProvider(create: (_) => ProductController()),
          ChangeNotifierProvider(create: (_) => SalesController()),
        ],
        child: ShopApp(authController: authController),
      ),
    );

    // App should start on the login page
    expect(find.text('Login'), findsOneWidget);
  });
}



