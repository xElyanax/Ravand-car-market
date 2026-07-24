import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ravand/data/car_repository.dart';
import 'package:ravand/state/app_controller.dart';

const _validCarsJson = '''
[
  {
    "cid": 10982,
    "type": "آریسان",
    "model": "2",
    "year": 1403,
    "price": 720000000,
    "change_percent": 1.41,
    "unique_id": "bbc99"
  }
]
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SourceArena diagnostics', () {
    for (final testCase in const [
      (status: 401, expected: 'توکن SourceArena نامعتبر'),
      (status: 403, expected: 'توکن SourceArena نامعتبر'),
      (status: 429, expected: 'سهمیه درخواست‌های SourceArena'),
      (status: 503, expected: 'موقتاً دچار اختلال'),
    ]) {
      test('classifies HTTP ${testCase.status}', () async {
        final repository = await _repositoryWith(
          MockClient(
            (_) async => http.Response('untrusted response', testCase.status),
          ),
        );

        final result = await repository.fetchLatest(forceRefresh: true);

        expect(result.source, CarDataSource.demo);
        expect(result.error, contains(testCase.expected));
        expect(result.error, isNot(contains('candidate-secret')));
        repository.dispose();
      });
    }

    test('classifies a timeout', () async {
      final repository = await _repositoryWith(
        MockClient(
          (_) => Future<http.Response>.delayed(
            const Duration(seconds: 1),
            () => http.Response(_validCarsJson, 200),
          ),
        ),
        timeout: const Duration(milliseconds: 1),
      );

      final result = await repository.fetchLatest(forceRefresh: true);

      expect(result.error, contains('مهلت اتصال'));
      repository.dispose();
    });

    test(
      'classifies a client/CORS-network failure without leaking details',
      () async {
        final repository = await _repositoryWith(
          MockClient(
            (request) async => throw http.ClientException(
              'Failed to fetch candidate-secret',
              request.url,
            ),
          ),
        );

        final result = await repository.fetchLatest(forceRefresh: true);

        expect(result.error, contains('ارتباط شبکه'));
        expect(result.error, isNot(contains('candidate-secret')));
        repository.dispose();
      },
    );

    test('classifies malformed JSON', () async {
      final repository = await _repositoryWith(
        MockClient((_) async => http.Response('<html>not JSON</html>', 200)),
      );

      final result = await repository.fetchLatest(forceRefresh: true);

      expect(result.error, contains('JSON معتبر'));
      repository.dispose();
    });

    test('classifies a successful HTTP error envelope', () async {
      final repository = await _repositoryWith(
        MockClient(
          (_) async => http.Response(
            '{"success":false,"message":"invalid token candidate-secret"}',
            200,
          ),
        ),
      );

      final result = await repository.fetchLatest(forceRefresh: true);

      expect(result.error, contains('توکن SourceArena نامعتبر'));
      expect(result.error, isNot(contains('candidate-secret')));
      repository.dispose();
    });
  });

  group('token persistence', () {
    test('restores the previous runtime token after a failed check', () async {
      const tokenKey = 'sourcearena_api_token_v2';
      SharedPreferences.setMockInitialValues({tokenKey: 'previous-token'});
      final preferences = await SharedPreferences.getInstance();
      final repository = CarRepository(
        client: MockClient((_) async => http.Response('{}', 401)),
        preferences: preferences,
        runtimeToken: 'previous-token',
      );
      final controller = AppController(
        preferences: preferences,
        repository: repository,
      );

      final connected = await controller.connectWithToken('candidate-secret');

      expect(connected, isFalse);
      expect(repository.runtimeToken, 'previous-token');
      expect(preferences.getString(tokenKey), 'previous-token');
      expect(controller.errorMessage, contains('توکن SourceArena نامعتبر'));
      controller.dispose();
    });

    test(
      'persists a candidate only after a successful network check',
      () async {
        const tokenKey = 'sourcearena_api_token_v2';
        SharedPreferences.setMockInitialValues({tokenKey: 'previous-token'});
        final preferences = await SharedPreferences.getInstance();
        final repository = CarRepository(
          client: MockClient(
            (_) async => http.Response(
              _validCarsJson,
              200,
              headers: const {
                'content-type': 'application/json; charset=utf-8',
              },
            ),
          ),
          preferences: preferences,
          runtimeToken: 'previous-token',
        );
        final controller = AppController(
          preferences: preferences,
          repository: repository,
        );

        final connected = await controller.connectWithToken('candidate-token');

        expect(connected, isTrue);
        expect(repository.runtimeToken, 'candidate-token');
        expect(preferences.getString(tokenKey), 'candidate-token');
        expect(controller.errorMessage, isNull);
        controller.dispose();
      },
    );
  });
}

Future<CarRepository> _repositoryWith(
  http.Client client, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return CarRepository(
    client: client,
    preferences: preferences,
    runtimeToken: 'candidate-secret',
    timeout: timeout,
  );
}
