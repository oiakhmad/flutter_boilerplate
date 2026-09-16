/// App-wide, non-secret constants that aren't specific to any one feature.
abstract final class AppConstants {
  static const String databaseFileName = 'app_database.db';

  static const int nameMinLength = 2;
  static const int nameMaxLength = 60;
}
