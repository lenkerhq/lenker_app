import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import 'api_client.dart';
import 'auth_service.dart';

class SubscriptionService extends ChangeNotifier {
  final ApiClient _api;
  final AuthService _auth;

  SubscriptionAccess? _access;
  String? _error;
  bool _loading = false;

  SubscriptionService(this._api, this._auth);

  SubscriptionAccess? get access => _access;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> refresh() async {
    if (!_auth.isAuthenticated) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getSubscriptionAccess(_auth.panelUrl!, _auth.accessToken!);
      _access = SubscriptionAccess.fromJson(data);
      _error = null;
    } on ApiException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
