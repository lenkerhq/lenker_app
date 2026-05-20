import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lenker_app/services/api_client.dart';

void main() {
  group('ApiClient account methods', () {
    test('register uses centralized base URL', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'https://api.lenker.test/api/v1/accounts/register');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'user@test.com');
        expect(body['password'], 'password123');
        return http.Response(
          jsonEncode({
            'data': {
              'account': {'id': 'acc-1', 'email': 'user@test.com', 'status': 'active'},
              'session': {'id': 'sess-1', 'account_id': 'acc-1', 'token': 'tok-abc', 'expires_at': '2026-06-01T00:00:00Z'},
            }
          }),
          201,
        );
      });

      final api = ApiClient(mockClient, 'https://api.lenker.test');
      final result = await api.register('user@test.com', 'password123');

      expect(result.token, 'tok-abc');
      expect(result.accountId, 'acc-1');
      expect(result.email, 'user@test.com');
    });

    test('login uses centralized base URL', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'https://api.lenker.test/api/v1/accounts/login');
        return http.Response(
          jsonEncode({
            'data': {
              'account': {'id': 'acc-2', 'email': 'user@test.com', 'status': 'active'},
              'session': {'id': 'sess-2', 'account_id': 'acc-2', 'token': 'tok-def', 'expires_at': '2026-06-01T00:00:00Z'},
            }
          }),
          200,
        );
      });

      final api = ApiClient(mockClient, 'https://api.lenker.test');
      final result = await api.login('user@test.com', 'password123');

      expect(result.token, 'tok-def');
      expect(result.accountId, 'acc-2');
    });

    test('login throws ApiException on 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'invalid_credentials', 'message': 'invalid email or password'}
          }),
          401,
        );
      });

      final api = ApiClient(mockClient, 'https://api.lenker.test');
      expect(
        () => api.login('user@test.com', 'wrong'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('register throws ApiException on 409 email taken', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'email_taken', 'message': 'email already registered'}
          }),
          409,
        );
      });

      final api = ApiClient(mockClient, 'https://api.lenker.test');
      expect(
        () => api.register('user@test.com', 'password123'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'email_taken')),
      );
    });

    test('logout uses centralized base URL', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'https://api.lenker.test/api/v1/accounts/logout');
        expect(request.headers['Authorization'], 'Bearer my-token');
        return http.Response(
          jsonEncode({'data': {'status': 'logged_out'}}),
          200,
        );
      });

      final api = ApiClient(mockClient, 'https://api.lenker.test');
      await api.logout('my-token');
    });
  });
}
