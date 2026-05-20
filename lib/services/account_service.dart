import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages consumer account session (separate from subscription access token).
class AccountService {
  static const _keyAccountToken = 'lenker_account_token';
  static const _keyAccountEmail = 'lenker_account_email';
  static const _keyAccountId = 'lenker_account_id';

  final FlutterSecureStorage _storage;

  String? _token;
  String? _email;
  String? _accountId;

  AccountService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get email => _email;
  String? get accountId => _accountId;

  Future<void> load() async {
    _token = await _storage.read(key: _keyAccountToken);
    _email = await _storage.read(key: _keyAccountEmail);
    _accountId = await _storage.read(key: _keyAccountId);
  }

  Future<void> save({
    required String token,
    required String email,
    required String accountId,
  }) async {
    _token = token;
    _email = email;
    _accountId = accountId;
    await _storage.write(key: _keyAccountToken, value: token);
    await _storage.write(key: _keyAccountEmail, value: email);
    await _storage.write(key: _keyAccountId, value: accountId);
  }

  Future<void> clear() async {
    _token = null;
    _email = null;
    _accountId = null;
    await _storage.delete(key: _keyAccountToken);
    await _storage.delete(key: _keyAccountEmail);
    await _storage.delete(key: _keyAccountId);
  }
}
