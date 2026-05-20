import 'secure_kv_store.dart';

/// Manages consumer account session (separate from subscription access token).
class AccountService {
  static const _keyAccountToken = 'lenker_account_token';
  static const _keyAccountEmail = 'lenker_account_email';
  static const _keyAccountId = 'lenker_account_id';

  final SecureKvStore _storage;

  String? _token;
  String? _email;
  String? _accountId;

  AccountService(this._storage);

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get email => _email;
  String? get accountId => _accountId;

  Future<void> load() async {
    _token = await _storage.read(_keyAccountToken);
    _email = await _storage.read(_keyAccountEmail);
    _accountId = await _storage.read(_keyAccountId);
  }

  Future<void> save({
    required String token,
    required String email,
    required String accountId,
  }) async {
    _token = token;
    _email = email;
    _accountId = accountId;
    await _storage.write(_keyAccountToken, token);
    await _storage.write(_keyAccountEmail, email);
    await _storage.write(_keyAccountId, accountId);
  }

  Future<void> clear() async {
    _token = null;
    _email = null;
    _accountId = null;
    await _storage.delete(_keyAccountToken);
    await _storage.delete(_keyAccountEmail);
    await _storage.delete(_keyAccountId);
  }
}
