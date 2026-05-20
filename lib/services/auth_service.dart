import 'secure_kv_store.dart';

class AuthService {
  static const _keyAccessToken = 'lenker_access_token';
  static const _keyPanelUrl = 'lenker_panel_url';
  static const _keySubscriptionId = 'lenker_subscription_id';

  final SecureKvStore _storage;

  String? _accessToken;
  String? _panelUrl;
  String? _subscriptionId;

  AuthService(this._storage);

  bool get isAuthenticated => _accessToken != null && _panelUrl != null;
  String? get accessToken => _accessToken;
  String? get panelUrl => _panelUrl;
  String? get subscriptionId => _subscriptionId;

  Future<void> load() async {
    _accessToken = await _storage.read(_keyAccessToken);
    _panelUrl = await _storage.read(_keyPanelUrl);
    _subscriptionId = await _storage.read(_keySubscriptionId);
  }

  Future<void> save({
    required String accessToken,
    required String panelUrl,
    required String subscriptionId,
  }) async {
    _accessToken = accessToken;
    _panelUrl = panelUrl;
    _subscriptionId = subscriptionId;
    await _storage.write(_keyAccessToken, accessToken);
    await _storage.write(_keyPanelUrl, panelUrl);
    await _storage.write(_keySubscriptionId, subscriptionId);
  }

  Future<void> clear() async {
    _accessToken = null;
    _panelUrl = null;
    _subscriptionId = null;
    await _storage.deleteAll();
  }
}
