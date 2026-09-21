import 'dart:io';

import 'package:flutter_clean_boilerplate/core/config/app_config.dart';
import 'package:flutter_clean_boilerplate/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

/// Expected `DB_NAME` per environment, mirroring `config/<env>.json`.
///
/// Deliberately duplicated instead of derived from [AppConfig]: the point
/// of the test is to fail if a config file and the central config class
/// ever disagree.
const Map<String, String> _expectedDbNameByEnv = {
  'dev': 'my_app_dev.db',
  'staging': 'my_app_staging.db',
  'production': 'my_app_production.db',
};

/// Expected `APP_ENV` -> [AppEnvironment] mapping per config file.
const Map<String, AppEnvironment> _expectedEnvironmentByEnv = {
  'dev': AppEnvironment.dev,
  'staging': AppEnvironment.staging,
  'production': AppEnvironment.production,
};

/// Non-empty only when the test run is given
/// `--dart-define-from-file=config/<env>.json` (or `-DAPP_ENV=...`).
const String _declaredEnv = String.fromEnvironment('APP_ENV');

void main() {
  group('AppEnvironment.fromName', () {
    test('parses known environment names', () {
      expect(AppEnvironment.fromName('dev'), AppEnvironment.dev);
      expect(AppEnvironment.fromName('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromName('production'), AppEnvironment.production);
    });

    test('tolerates casing and surrounding whitespace', () {
      expect(AppEnvironment.fromName(' Staging '), AppEnvironment.staging);
      expect(AppEnvironment.fromName('PRODUCTION'), AppEnvironment.production);
    });

    test('degrades to dev for unknown or empty input', () {
      expect(AppEnvironment.fromName(''), AppEnvironment.dev);
      expect(AppEnvironment.fromName('qa'), AppEnvironment.dev);
    });
  });

  group('config/<env>.json database names', () {
    test('every environment points at a distinct Sembast file', () {
      expect(_expectedDbNameByEnv.values.toSet(), hasLength(3));
      for (final name in _expectedDbNameByEnv.values) {
        expect(name, endsWith('.db'));
      }
    });
  });

  group('Sembast integration', () {
    test('opens, writes, and reads back using AppConfig.dbName', () async {
      final directory = Directory.systemTemp.createTempSync('app_config_test');
      addTearDown(() => directory.deleteSync(recursive: true));

      final database = await databaseFactoryIo.openDatabase(
        p.join(directory.path, AppConfig.dbName),
      );
      addTearDown(database.close);

      final store = stringMapStoreFactory.store('probe');
      await store
          .record('1')
          .put(database, <String, Object?>{'env': AppConfig.environmentName});

      expect(
          File(p.join(directory.path, AppConfig.dbName)).existsSync(), isTrue);
      expect(await store.record('1').get(database),
          {'env': AppConfig.environmentName});
    });
  });

  group('without --dart-define-from-file (plain `flutter run`)', () {
    test(
      'falls back to the bundled database name and dev defaults',
      () {
        expect(AppConfig.isConfigured, isFalse);
        expect(AppConfig.environmentName, AppConfig.defaultEnvironmentName);
        expect(AppConfig.environment, AppEnvironment.dev);
        expect(AppConfig.dbName, AppConstants.databaseFileName);
        expect(AppConfig.apiBaseUrl, isEmpty);
        expect(AppConfig.appName, isEmpty);
        expect(AppConfig.enableLogging, isFalse);
        expect(AppConfig.apiTimeoutSeconds, AppConfig.defaultApiTimeoutSeconds);
      },
      skip: _declaredEnv.isEmpty
          ? null
          : 'run without --dart-define-from-file to cover the fallback path',
    );
  });

  group('with --dart-define-from-file=config/<env>.json', () {
    test(
      'reads the active environment and its own database name',
      () {
        expect(AppConfig.isConfigured, isTrue);
        expect(AppConfig.environmentName, _declaredEnv);
        expect(AppConfig.environment, _expectedEnvironmentByEnv[_declaredEnv]);
        expect(AppConfig.dbName, _expectedDbNameByEnv[_declaredEnv]);
        expect(AppConfig.apiBaseUrl, isNotEmpty);
        expect(AppConfig.appName, isNotEmpty);
        expect(AppConfig.apiTimeoutSeconds, greaterThan(0));
      },
      skip: _declaredEnv.isEmpty
          ? 'run with --dart-define-from-file=config/<env>.json'
          : null,
    );
  });
}
