import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

enum AuthMode { signIn, register }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _accountFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _panelUrlController = TextEditingController(text: 'https://');
  final _tokenController = TextEditingController();

  AuthMode _authMode = AuthMode.signIn;
  bool _accountLoading = false;
  bool _handoffLoading = false;
  String? _accountError;
  String? _handoffError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _panelUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submitAccount() async {
    if (!_accountFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _accountLoading = true;
      _accountError = null;
    });

    try {
      final api = context.read<ApiClient>();
      final accountService = context.read<AccountService>();

      final AccountAuthResult result;
      if (_authMode == AuthMode.register) {
        result = await api.register(email, password);
      } else {
        result = await api.login(email, password);
      }

      await accountService.save(
        token: result.token,
        email: result.email,
        accountId: result.accountId,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on ApiException catch (e) {
      setState(() => _accountError = e.toString());
    } catch (_) {
      setState(() => _accountError = 'Connection failed. Please try again.');
    } finally {
      if (mounted) setState(() => _accountLoading = false);
    }
  }

  Future<void> _claim() async {
    final panelUrl = _panelUrlController.text.trim().replaceAll(RegExp(r'/+$'), '');
    final token = _tokenController.text.trim();
    if (panelUrl.isEmpty || panelUrl == 'https://' || token.isEmpty) {
      setState(() => _handoffError = 'Panel URL and invite token are required.');
      return;
    }
    setState(() {
      _handoffLoading = true;
      _handoffError = null;
    });
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
      setState(() => _handoffError = e.toString());
    } catch (_) {
      setState(() => _handoffError = 'Connection failed. Check the panel URL.');
    } finally {
      if (mounted) setState(() => _handoffLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Lenker', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your Lenker account or create one to start using VPN services.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                _buildAccountCard(context),
                const SizedBox(height: 16),
                _buildInviteCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    final isRegister = _authMode == AuthMode.register;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _accountFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<AuthMode>(
                segments: const [
                  ButtonSegment(value: AuthMode.signIn, label: Text('Sign in')),
                  ButtonSegment(value: AuthMode.register, label: Text('Create account')),
                ],
                selected: {_authMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _authMode = selection.first;
                    _accountError = null;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                validator: _validatePassword,
              ),
              if (isRegister) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm password'),
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: _validateConfirmPassword,
                ),
              ],
              if (_accountError != null) ...[
                const SizedBox(height: 14),
                Text(
                  _accountError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _accountLoading ? null : _submitAccount,
                child: _accountLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isRegister ? 'Create account' : 'Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text('Continue with invite token'),
        subtitle: const Text('Use this for current provider handoff links.'),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          TextField(
            controller: _panelUrlController,
            decoration: const InputDecoration(
              labelText: 'Panel URL',
              hintText: 'https://panel.myvpn.com',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Invite token',
              hintText: 'lnkhi_...',
            ),
          ),
          if (_handoffError != null) ...[
            const SizedBox(height: 14),
            Text(_handoffError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _handoffLoading ? null : _claim,
            child: _handoffLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Connect with invite'),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required.';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_authMode != AuthMode.register) return null;
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }
}
