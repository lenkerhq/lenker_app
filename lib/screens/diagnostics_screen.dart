import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final sub = context.watch<SubscriptionService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row('Panel URL', auth.panelUrl ?? 'not set'),
            _row('Token status', auth.isAuthenticated ? 'stored' : 'missing'),
            _row('Subscription ID', auth.subscriptionId ?? 'none'),
            _row('Last error', sub.error ?? 'none'),
            _row('Subscription status', sub.access?.status ?? 'unknown'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: sub.refresh,
              child: const Text('Refresh subscription'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await auth.clear();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: SelectableText(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))),
        ],
      ),
    );
  }
}
