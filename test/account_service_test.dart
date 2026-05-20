import 'package:flutter_test/flutter_test.dart';
import 'package:lenker_app/services/account_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  group('AccountService', () {
    test('isLoggedIn is false initially', () {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AccountService();
      expect(service.isLoggedIn, isFalse);
      expect(service.token, isNull);
      expect(service.email, isNull);
    });

    test('save and read back values', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AccountService();

      await service.save(
        token: 'test-token',
        email: 'user@test.com',
        accountId: 'acc-123',
      );

      expect(service.isLoggedIn, isTrue);
      expect(service.token, 'test-token');
      expect(service.email, 'user@test.com');
      expect(service.accountId, 'acc-123');
    });

    test('clear removes all values', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AccountService();

      await service.save(
        token: 'test-token',
        email: 'user@test.com',
        accountId: 'acc-123',
      );
      await service.clear();

      expect(service.isLoggedIn, isFalse);
      expect(service.token, isNull);
      expect(service.email, isNull);
    });

    test('load reads from storage', () async {
      FlutterSecureStorage.setMockInitialValues({
        'lenker_account_token': 'stored-token',
        'lenker_account_email': 'stored@test.com',
        'lenker_account_id': 'acc-456',
      });
      final service = AccountService();
      await service.load();

      expect(service.isLoggedIn, isTrue);
      expect(service.token, 'stored-token');
      expect(service.email, 'stored@test.com');
      expect(service.accountId, 'acc-456');
    });
  });
}
