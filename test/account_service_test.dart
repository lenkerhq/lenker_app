import 'package:flutter_test/flutter_test.dart';
import 'package:lenker_app/services/account_service.dart';
import 'package:lenker_app/services/secure_kv_store.dart';

void main() {
  group('AccountService', () {
    test('isLoggedIn is false initially', () {
      final service = AccountService(SecureKvStore.inMemory());
      expect(service.isLoggedIn, isFalse);
      expect(service.token, isNull);
      expect(service.email, isNull);
    });

    test('save and read back values', () async {
      final service = AccountService(SecureKvStore.inMemory());

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
      final service = AccountService(SecureKvStore.inMemory());

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
      final service = AccountService(
        SecureKvStore.inMemory({
          'lenker_account_token': 'stored-token',
          'lenker_account_email': 'stored@test.com',
          'lenker_account_id': 'acc-456',
        }),
      );
      await service.load();

      expect(service.isLoggedIn, isTrue);
      expect(service.token, 'stored-token');
      expect(service.email, 'stored@test.com');
      expect(service.accountId, 'acc-456');
    });
  });
}
