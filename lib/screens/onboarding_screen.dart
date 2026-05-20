import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _panelUrlController = TextEditingController(text: 'https://');
  final _tokenController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _panelUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    final panelUrl = _panelUrlController.text.trim().replaceAll(RegExp(r'/+$'), '');
    final token = _tokenController.text.trim();
    if (panelUrl.isEmpty || token.isEmpty) {
      setState(() => _error = 'Panel URL and invite token are required.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final auth = context.read<AuthService>();
      final result = await api.claimHandoff(panelUrl, token);
      await auth.save(
        accessToken: result.accessToken,
        panelUrl: panelUrl,
        subscriptionId: result.subscriptionId,
      );
      if (!mounted) return;
      await context.read<SubscriptionService>().refresh();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on ApiException catch (e) {
      setState(() => _error = e.toString());
    } catch (e) {
      setState(() => _error = 'Connection failed. Check the panel URL.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Lenker', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text('Enter your provider panel URL and invite token to get started.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                TextField(
                  controller: _panelUrlController,
                  decoration: const InputDecoration(labelText: 'Panel URL', hintText: 'https://panel.myvpn.com'),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(labelText: 'Invite token', hintText: 'lnkhi_...'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _claim,
                  child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
