import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.setTitle('Lenker');
  await windowManager.setMinimumSize(const Size(400, 600));
  await windowManager.setSize(const Size(480, 720));

  final authService = AuthService();
  await authService.load();

  final apiClient = ApiClient();
  final subscriptionService = SubscriptionService(apiClient, authService);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<SubscriptionService>.value(value: subscriptionService),
      ],
      child: LenkerApp(isAuthenticated: authService.isAuthenticated),
    ),
  );
}
