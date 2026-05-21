import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'services/api_client.dart';
import 'services/account_service.dart';
import 'services/auth_service.dart';
import 'services/secure_kv_store.dart';
import 'services/subscription_service.dart';
import 'services/vpn_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.setTitle('Lenker');
  await windowManager.setMinimumSize(const Size(400, 600));
  await windowManager.setSize(const Size(480, 720));

  final storage = await SecureKvStore.create();

  final authService = AuthService(storage);
  await authService.load();

  final accountService = AccountService(storage);
  await accountService.load();

  final apiClient = ApiClient();
  final subscriptionService = SubscriptionService(apiClient, authService);

  final isAuthenticated = accountService.isLoggedIn || authService.isAuthenticated;

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        Provider<AccountService>.value(value: accountService),
        ChangeNotifierProvider<SubscriptionService>.value(value: subscriptionService),
        ChangeNotifierProvider<VpnEngine>(create: (_) => VpnEngine()),
      ],
      child: LenkerApp(isAuthenticated: isAuthenticated),
    ),
  );
}
