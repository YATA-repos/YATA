/// アプリケーション全体で使用される定数値
/// 
/// ハードコードされた値を集約し、保守性を向上させるためのファイルです。
class AppConstants {
  AppConstants._(); // プライベートコンストラクタ

  // ===== チャート関連定数 =====
  
  /// 数値抽出用の正規表現パターン
  /// 例: "¥1,000" -> 1000, "45個" -> 45
  static const String numericExtractionPattern = r"[\d,]+";
  
  /// チャートラベルの最大文字数
  static const int chartLabelMaxLength = 8;
  
  /// カンマ文字（数値フォーマット用）
  static const String commaChar = ",";

  // ===== リアルタイム通信関連定数 =====
  
  /// リアルタイム通信の最大再接続試行回数
  static const int maxReconnectAttempts = 5;
  
  /// リアルタイム通信の再接続間隔（秒）
  static const int reconnectDelaySeconds = 5;
  
  /// デフォルトのリアルタイムイベントタイプ
  static const List<String> defaultRealtimeEventTypes = <String>[
    "INSERT", 
    "UPDATE", 
    "DELETE"
  ];

  // ===== UI関連定数 =====
  
  /// デフォルトのSnackBar表示時間（秒）
  static const int defaultSnackBarDurationSeconds = 4;
  
  /// 再試行可能エラーのSnackBar表示時間（秒）
  static const int retryableErrorSnackBarDurationSeconds = 6;

  // ===== アニメーション関連定数 =====
  
  /// デフォルトのアニメーション時間（ミリ秒）
  static const int defaultAnimationDurationMs = 300;
  
  /// ローディング表示の最小時間（ミリ秒）
  static const int minimumLoadingDurationMs = 500;

  // ===== ページネーション関連定数 =====
  
  /// デフォルトのページサイズ
  static const int defaultPageSize = 20;
  
  /// 検索結果の最大表示件数
  static const int maxSearchResultsCount = 100;

  // ===== フォームバリデーション関連定数 =====
  
  /// パスワードの最小文字数
  static const int minPasswordLength = 8;
  
  /// ユーザー名の最大文字数
  static const int maxUsernameLength = 50;
  
  /// メモ・説明文の最大文字数
  static const int maxDescriptionLength = 500;
}