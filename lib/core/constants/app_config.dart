/// アプリケーション設定定数
///
/// ビジネスロジック層や全体で使用される設定値を管理します。
class AppConfig {
  AppConfig._();

  // API関連
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // UI関連タイムアウト
  static const Duration debounceTimeout = Duration(milliseconds: 300);
  static const Duration sessionCheckInterval = Duration(minutes: 1);
  static const Duration stockMonitoringInterval = Duration(minutes: 5);
  static const Duration sessionExpiryBuffer = Duration(minutes: 5);
  static const Duration messageDisplayDuration = Duration(seconds: 5);

  // データ制限
  static const int maxItemsPerPage = 50;
  static const int maxSearchResults = 100;
  static const int maxImageSizeMB = 5;
  static const int defaultItemsPerPage = 10;

  // 閾値・アラート設定
  static const int defaultAlertThreshold = 10;
  static const int maxThreshold = 30;
  static const int minQuantity = 1;
  static const int maxQuantity = 1000;

  // テキスト制限（ビジネスロジック用）
  static const int maxItemNameLength = 100;
  static const int maxDescriptionLength = 1000;

  // フォーマット
  static const String dateFormat = "yyyy/MM/dd";
  static const String timeFormat = "HH:mm";
  static const String dateTimeFormat = "yyyy/MM/dd HH:mm";
  static const String currencySymbol = "¥";

  // ローカルストレージキー
  static const String themeKey = "app_theme";
  static const String languageKey = "app_language";
  static const String lastLoginKey = "last_login";
  static const String userPreferencesKey = "user_preferences";
}
