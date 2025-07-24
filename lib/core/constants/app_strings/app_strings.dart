class AppStrings {
  AppStrings._();
  // AppStringsの命名規則
  // - lowerCamelCase
  // - [カテゴリ][用途][詳細]で構成

  // カテゴリ:
  // - title: タイトル
  // - button: ボタンのラベル
  // - tooltip: ツールチップのテキスト
  // - description: 説明
  // - placeholder: プレースホルダー
  // - error: 表示用のエラーメッセージ(log enumと名称対応)
  // - text: その他テキスト

  // ======================== title ========================
  static const String titleApp = "YATA";
  static const String titleHome = "ホーム";
  static const String titleSettings = "設定";
  static const String titleOrderHistory = "注文履歴";
  static const String titleAnalytics = "売上分析";
  static const String titleSelectMenu = "メニュー選択";

  // ======================== tab ========================
  static const String navHome = "ホーム";
  static const String navOrderHistory = "注文履歴";
  static const String navAnalytics = "売上分析";

  // ======================== button ========================

  // ======================== description ========================
  static const String descriptionSelectMenu = "商品をタップして注文に追加";

  // ======================== placeholder ========================
  static const String placeholderSearchMenu = "メニューを検索";

  // ======================== text ========================
  static const String textNotApplicable = "N/A";
}
