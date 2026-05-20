import 'dart:convert';
import 'package:http/http.dart' as http;

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

class ApiClient {
  final http.Client _client;

  ApiClient([http.Client? client]) : _client = client ?? http.Client();

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
