import 'dart:convert';
import 'package:http/http.dart' as http;

/// Default Lenker account API base URL.
///
/// Override for a deployed panel/API with:
/// `flutter run -d macos --dart-define=LENKER_ACCOUNT_API_URL=https://api.example.com`
const defaultAccountApiUrl = String.fromEnvironment(
  'LENKER_ACCOUNT_API_URL',
  defaultValue: 'https://n8n.tayca.store/panel-api',
);

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  ApiException(this.statusCode, this.code, this.message);

  @override
  String toString() => '$message ($code)';
}

class HandoffResult {
  final String accessToken;
  final String subscriptionId;

  HandoffResult({required this.accessToken, required this.subscriptionId});
}

class AccountAuthResult {
  final String token;
  final String accountId;
  final String email;

  AccountAuthResult({required this.token, required this.accountId, required this.email});
}

class ApiClient {
  final http.Client _client;
  final String accountApiUrl;

  ApiClient([http.Client? client, String? accountApiUrl])
      : _client = client ?? http.Client(),
        accountApiUrl = accountApiUrl ?? defaultAccountApiUrl;

  Future<AccountAuthResult> register(String email, String password) async {
    final uri = Uri.parse('$accountApiUrl/api/v1/accounts/register');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _parseResponse(response);
    final data = body['data'] as Map<String, dynamic>;
    final account = data['account'] as Map<String, dynamic>;
    final session = data['session'] as Map<String, dynamic>;
    return AccountAuthResult(
      token: session['token'] as String,
      accountId: account['id'] as String,
      email: account['email'] as String,
    );
  }

  Future<AccountAuthResult> login(String email, String password) async {
    final uri = Uri.parse('$accountApiUrl/api/v1/accounts/login');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _parseResponse(response);
    final data = body['data'] as Map<String, dynamic>;
    final account = data['account'] as Map<String, dynamic>;
    final session = data['session'] as Map<String, dynamic>;
    return AccountAuthResult(
      token: session['token'] as String,
      accountId: account['id'] as String,
      email: account['email'] as String,
    );
  }

  Future<void> logout(String token) async {
    final uri = Uri.parse('$accountApiUrl/api/v1/accounts/logout');
    final response = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    _parseResponse(response);
  }

  Future<HandoffResult> claimHandoff(String panelUrl, String inviteToken) async {
    final uri = Uri.parse('$panelUrl/api/v1/client/handoff/claim');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'invite_token': inviteToken}),
    );
    final body = _parseResponse(response);
    final data = body['data'] as Map<String, dynamic>;
    return HandoffResult(
      accessToken: data['access_token'] as String,
      subscriptionId: data['subscription_id'] as String,
    );
  }

  Future<Map<String, dynamic>> getSubscriptionAccess(String panelUrl, String accessToken) async {
    final uri = Uri.parse('$panelUrl/api/v1/client/subscription-access');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final body = _parseResponse(response);
    return body['data'] as Map<String, dynamic>;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(response.statusCode, 'parse_error', 'Invalid response from server');
    }
    if (response.statusCode >= 400) {
      final error = body['error'] as Map<String, dynamic>?;
      throw ApiException(
        response.statusCode,
        error?['code'] as String? ?? 'request_failed',
        error?['message'] as String? ?? 'Request failed (${response.statusCode})',
      );
    }
    return body;
  }
}
