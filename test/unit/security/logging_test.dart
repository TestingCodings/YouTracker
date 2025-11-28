import 'package:flutter_test/flutter_test.dart';

import 'package:you_tracker/src/logging/app_logger.dart';
import 'package:you_tracker/src/config/environment.dart';

void main() {
  group('LogRedactor', () {
    test('should redact sensitive keys', () {
      final data = {
        'accessToken': 'secret_access_token_123',
        'refreshToken': 'secret_refresh_token_456',
        'password': 'super_secret_password',
        'api_key': 'api_key_value',
        'userId': 'user_123', // Should NOT be redacted
      };

      final redacted = LogRedactor.redact(data);

      expect(redacted['accessToken'], '[REDACTED]');
      expect(redacted['refreshToken'], '[REDACTED]');
      expect(redacted['password'], '[REDACTED]');
      expect(redacted['api_key'], '[REDACTED]');
      expect(redacted['userId'], 'user_123'); // Not redacted
    });

    test('should redact keys containing sensitive substrings', () {
      final data = {
        'myAccessToken': 'token_value',
        'userPassword': 'password_value',
        'authToken': 'auth_value',
        'secretKey': 'secret_value',
        'regularData': 'normal_value',
      };

      final redacted = LogRedactor.redact(data);

      expect(redacted['myAccessToken'], '[REDACTED]');
      expect(redacted['userPassword'], '[REDACTED]');
      expect(redacted['authToken'], '[REDACTED]');
      expect(redacted['secretKey'], '[REDACTED]');
      expect(redacted['regularData'], 'normal_value');
    });

    test('should partially redact email addresses', () {
      final data = {
        'email': 'john.doe@example.com',
      };

      final redacted = LogRedactor.redact(data);

      expect(redacted['email'], 'jo***@example.com');
    });

    test('should partially redact phone numbers', () {
      final data = {
        'phone': '1234567890',
      };

      final redacted = LogRedactor.redact(data);

      // Last 4 digits should be visible
      expect(redacted['phone'], contains('7890'));
    });

    test('should redact bearer tokens in values', () {
      final data = {
        'header': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
      };

      final redacted = LogRedactor.redact(data);

      expect(redacted['header'], 'Bearer [REDACTED]');
    });

    test('should redact long alphanumeric strings that look like tokens', () {
      final data = {
        'someValue': 'aB3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7',
      };

      final redacted = LogRedactor.redact(data);

      expect(redacted['someValue'], '[REDACTED_TOKEN]');
    });

    test('should handle nested maps', () {
      final data = {
        'user': {
          'id': 'user_123',
          'credentials': {
            'password': 'secret_password',
            'apiKey': 'secret_key',
          },
        },
        'normalField': 'normal_value',
      };

      final redacted = LogRedactor.redact(data);

      final user = redacted['user'] as Map<String, dynamic>;
      expect(user['id'], 'user_123');
      
      final credentials = user['credentials'] as Map<String, dynamic>;
      expect(credentials['password'], '[REDACTED]');
      expect(credentials['apiKey'], '[REDACTED]');
    });

    test('should handle lists', () {
      final data = {
        'tokens': ['token1', 'token2'],
        'items': [
          {'password': 'secret'},
          {'name': 'visible'},
        ],
      };

      final redacted = LogRedactor.redact(data);

      final items = redacted['items'] as List;
      expect((items[0] as Map)['password'], '[REDACTED]');
      expect((items[1] as Map)['name'], 'visible');
    });

    test('should preserve non-string values', () {
      final data = {
        'count': 42,
        'enabled': true,
        'ratio': 3.14,
        'nullValue': null,
      };

      final redacted = LogRedactor.redact(data);

      expect(redacted['count'], 42);
      expect(redacted['enabled'], true);
      expect(redacted['ratio'], 3.14);
      expect(redacted['nullValue'], null);
    });

    test('should handle empty data', () {
      final data = <String, dynamic>{};
      final redacted = LogRedactor.redact(data);
      expect(redacted.isEmpty, true);
    });

    test('redactString should work on single strings', () {
      expect(
        LogRedactor.redactString('Bearer abc123'),
        'Bearer [REDACTED]',
      );
    });

    test('should redact credit card-like numbers', () {
      final data = {
        'cardNumber': '4111111111111111',
      };

      final redacted = LogRedactor.redact(data);

      // Should show only last 4 digits
      expect(redacted['cardNumber'], contains('1111'));
      expect(redacted['cardNumber'], contains('****'));
    });
  });

  group('AppLogger', () {
    late List<LogEntry> logEntries;
    late AppLogger logger;

    setUp(() {
      logEntries = [];
      logger = AppLogger('TestLogger', onLog: (entry) {
        logEntries.add(entry);
      });

      // Ensure environment is initialized for logging tests
      Environment.reset();
    });

    tearDown(() {
      Environment.reset();
    });

    test('should create log entries with correct level', () async {
      await Environment.initialize(EnvironmentType.development);

      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');

      expect(logEntries.length, 4);
      expect(logEntries[0].level, LogLevel.debug);
      expect(logEntries[1].level, LogLevel.info);
      expect(logEntries[2].level, LogLevel.warning);
      expect(logEntries[3].level, LogLevel.error);
    });

    test('should include logger name in entries', () async {
      await Environment.initialize(EnvironmentType.development);

      logger.info('Test message');

      expect(logEntries.first.name, 'TestLogger');
    });

    test('should include message in entries', () async {
      await Environment.initialize(EnvironmentType.development);

      logger.info('Test message content');

      expect(logEntries.first.message, 'Test message content');
    });

    test('should include timestamp in entries', () async {
      await Environment.initialize(EnvironmentType.development);

      final before = DateTime.now();
      logger.info('Test');
      final after = DateTime.now();

      final timestamp = logEntries.first.timestamp;
      expect(timestamp.isAfter(before) || timestamp.isAtSameMomentAs(before), true);
      expect(timestamp.isBefore(after) || timestamp.isAtSameMomentAs(after), true);
    });

    test('should include redacted data', () async {
      await Environment.initialize(EnvironmentType.development);

      logger.info('Login attempt', {
        'username': 'john',
        'password': 'secret123',
      });

      final data = logEntries.first.data!;
      expect(data['username'], 'john');
      expect(data['password'], '[REDACTED]');
    });

    test('should include exception in error logs', () async {
      await Environment.initialize(EnvironmentType.development);

      final exception = Exception('Test error');
      logger.error('Error occurred', null, exception);

      expect(logEntries.first.exception, exception);
    });

    test('debug logs should be skipped when not in debug mode', () async {
      await Environment.initialize(
        EnvironmentType.production,
        config: {'API_BASE_URL': 'https://api.example.com'},
      );

      logger.debug('Debug message');

      expect(logEntries.isEmpty, true);
    });

    test('info logs should work in production', () async {
      await Environment.initialize(
        EnvironmentType.production,
        config: {'API_BASE_URL': 'https://api.example.com'},
      );

      logger.info('Info message');

      expect(logEntries.length, 1);
    });
  });

  group('LogEntry', () {
    test('toString should include all relevant info', () {
      final entry = LogEntry(
        level: LogLevel.info,
        name: 'TestLogger',
        message: 'Test message',
        data: {'key': 'value'},
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      final str = entry.toString();

      expect(str, contains('info'));
      expect(str, contains('TestLogger'));
      expect(str, contains('Test message'));
      expect(str, contains('key'));
    });
  });

  group('Loggers', () {
    test('should have predefined logger instances', () {
      expect(Loggers.auth, isA<AppLogger>());
      expect(Loggers.sync, isA<AppLogger>());
      expect(Loggers.api, isA<AppLogger>());
      expect(Loggers.storage, isA<AppLogger>());
      expect(Loggers.navigation, isA<AppLogger>());
      expect(Loggers.analytics, isA<AppLogger>());
    });
  });

  group('LogLevel', () {
    test('should have all expected levels', () {
      expect(LogLevel.values.length, 4);
      expect(LogLevel.values, contains(LogLevel.debug));
      expect(LogLevel.values, contains(LogLevel.info));
      expect(LogLevel.values, contains(LogLevel.warning));
      expect(LogLevel.values, contains(LogLevel.error));
    });
  });
}
