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

  // ======================== button ========================
  static const String buttonCreateOrder = "オーダー作成";
  static const String buttonInventoryStatus = "在庫状況";

  static const String buttonOrderStatus = "注文状況画面";

  static const String buttonMenuCategoryAll = "すべて";
  static const String buttonMenuCategoryMainDish = "メイン料理";
  static const String buttonMenuCategorySideDish = "サイドメニュー";
  static const String buttonMenuCategoryDrink = "ドリンク";
  static const String buttonMenuCategoryDessert = "デザート";

  static const String buttonHome = titleHome;
  static const String buttonSettings = titleSettings;
  static const String buttonOrderHistory = titleOrderHistory;
  static const String buttonAnalytics = titleAnalytics;

  // ======================== description ========================
  static const String descriptionSelectMenu = "商品をタップして注文に追加";

  // ======================== placeholder ========================
  static const String placeholderSearchMenu = "メニューを検索";
}
