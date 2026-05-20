import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _keyAccessToken = 'lenker_access_token';
  static const _keyPanelUrl = 'lenker_panel_url';
  static const _keySubscriptionId = 'lenker_subscription_id';

  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _panelUrl;
  String? _subscriptionId;

  AuthService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  bool get isAuthenticated => _accessToken != null && _panelUrl != null;
  String? get accessToken => _accessToken;
  String? get panelUrl => _panelUrl;
  String? get subscriptionId => _subscriptionId;

  Future<void> load() async {
    _accessToken = await _storage.read(key: _keyAccessToken);
    _panelUrl = await _storage.read(key: _keyPanelUrl);
    _subscriptionId = await _storage.read(key: _keySubscriptionId);
  }

  Future<void> save({
    required String accessToken,
    required String panelUrl,
    required String subscriptionId,
  }) async {
    _accessToken = accessToken;
    _panelUrl = panelUrl;
    _subscriptionId = subscriptionId;
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyPanelUrl, value: panelUrl);
    await _storage.write(key: _keySubscriptionId, value: subscriptionId);
  }

  Future<void> clear() async {
    _accessToken = null;
    _panelUrl = null;
    _subscriptionId = null;
    await _storage.deleteAll();
  }
}
