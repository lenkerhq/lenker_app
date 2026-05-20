import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenker_app/app.dart';
import 'package:lenker_app/services/account_service.dart';
import 'package:lenker_app/services/api_client.dart';
import 'package:lenker_app/services/auth_service.dart';
import 'package:lenker_app/services/secure_kv_store.dart';
import 'package:lenker_app/services/subscription_service.dart';
import 'package:provider/provider.dart';

Widget _buildApp() {
  final storage = SecureKvStore.inMemory();
  final authService = AuthService(storage);
  final apiClient = ApiClient();
  final accountService = AccountService(storage);
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      Provider<AuthService>.value(value: authService),
      Provider<AccountService>.value(value: accountService),
      ChangeNotifierProvider<SubscriptionService>(
        create: (_) => SubscriptionService(apiClient, authService),
      ),
    ],
    child: const LenkerApp(isAuthenticated: false),
  );
}

void main() {
  group('OnboardingScreen', () {
    testWidgets('shows account auth form without Panel URL', (tester) async {
      await tester.pumpWidget(_buildApp());

      expect(find.text('Lenker'), findsOneWidget);
      expect(find.text('Sign in'), findsAtLeastNWidgets(1));
      expect(find.text('Create account'), findsAtLeastNWidgets(1));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      // Panel URL should NOT be visible in the main auth card (only inside invite)
      expect(find.text('Continue with invite token'), findsOneWidget);
    });

    testWidgets('shows confirm password in register mode', (tester) async {
      await tester.pumpWidget(_buildApp());

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm password'), findsOneWidget);
    });

    testWidgets('Panel URL only visible inside invite token section', (tester) async {
      await tester.pumpWidget(_buildApp());

      // Panel URL not visible before expanding invite section
      expect(find.text('Panel URL'), findsNothing);

      // Expand invite section
      await tester.tap(find.text('Continue with invite token'));
      await tester.pumpAndSettle();

      // Now Panel URL is visible
      expect(find.text('Panel URL'), findsOneWidget);
    });
  });
}
