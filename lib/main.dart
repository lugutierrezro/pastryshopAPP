import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/order_provider.dart';
import 'presentation/providers/supplier_provider.dart';
import 'presentation/providers/purchase_provider.dart';
import 'presentation/providers/employee_provider.dart';
import 'presentation/providers/log_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/role_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.init(); // restore session
  runApp(PastryShopApp(authProvider: authProvider));
}

class PastryShopApp extends StatelessWidget {
  final AuthProvider authProvider;
  const PastryShopApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => LogProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (_, auth, __) => MaterialApp.router(
          title: 'La Pastelería',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router(auth),
        ),
      ),
    );
  }
}
