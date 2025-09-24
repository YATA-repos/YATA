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
  static const String titleOrderStatus = "注文状況";
  static const String titleAnalytics = "売上分析";
  static const String titleInventory = "在庫管理";
  static const String titleMenu = "メニュー管理";
  static const String titleSelectMenu = "メニュー選択";

  // ======================== tab ========================
  static const String navHome = "ホーム";
  static const String navOrderHistory = "注文履歴";
  static const String navOrderStatus = "注文状況";
  static const String navAnalytics = "売上分析";
  static const String navInventory = "在庫管理";
  static const String navMenu = "メニュー管理";

  // ======================== button ========================
  static const String buttonGoogleLogin = "Googleでログイン";

  // ======================== description ========================
  static const String descriptionApp = "小規模レストラン向け在庫・注文管理システム";
  static const String descriptionSelectMenu = "商品をタップして注文に追加";
  static const String descriptionGoogleAuth = "セキュアなGoogle認証を使用してログインします";

  // ======================== placeholder ========================
  static const String placeholderSearchMenu = "メニューを検索";

  // ======================== error ========================
  static const String errorAuthFailed = "認証に失敗しました。もう一度お試しください。";
  static const String errorAuthGeneral = "認証エラー";

  // ======================== validation errors ========================
  // 基本バリデーション
  static const String validationRequired = "は必須です";
  static const String validationMinLength = "文字以上で入力してください";
  static const String validationMaxLength = "文字以下で入力してください";
  static const String validationInvalidFormat = "の形式が正しくありません";
  static const String validationInvalidNumber = "は数値で入力してください";
  static const String validationMinValue = "以上で入力してください";
  static const String validationMaxValue = "以下で入力してください";

  // 業務固有バリデーション
  static const String validationPriceRequired = "価格は必須です";
  static const String validationPriceInvalidNumber = "価格は有効な数値で入力してください";
  static const String validationPriceNonNegative = "価格は0以上で入力してください";
  static const String validationPriceMinValue = "価格は{0}円以上で入力してください";
  static const String validationPriceMaxValue = "価格は{0}円以下で入力してください";
  static const String validationPriceInteger = "価格は整数で入力してください";

  static const String validationQuantityRequired = "数量は必須です";
  static const String validationQuantityInvalidNumber = "数量は数値で入力してください";
  static const String validationQuantityNonNegative = "数量は0以上で入力してください";
  static const String validationQuantityMinValue = "数量は{0}以上で入力してください";
  static const String validationQuantityMaxValue = "数量は{0}以下で入力してください";
  static const String validationQuantityInteger = "数量は整数で入力してください";

  static const String validationMaterialNameRequired = "材料名は必須です";
  static const String validationMaterialNameMinLength = "材料名は{0}文字以上で入力してください";
  static const String validationMaterialNameMaxLength = "材料名は{0}文字以下で入力してください";
  static const String validationMaterialNameInvalidChars = "材料名に使用できない文字が含まれています";
  static const String validationMaterialNameWhitespace = "材料名の前後に空白文字は入力できません";

  static const String validationCategoryNameRequired = "カテゴリ名は必須です";
  static const String validationCategoryNameMinLength = "カテゴリ名は{0}文字以上で入力してください";
  static const String validationCategoryNameMaxLength = "カテゴリ名は{0}文字以下で入力してください";
  static const String validationCategoryNameInvalidChars = "カテゴリ名に使用できない文字が含まれています";
  static const String validationCategoryNameWhitespace = "カテゴリ名の前後に空白文字は入力できません";

  static const String validationMenuNameRequired = "メニュー名は必須です";
  static const String validationMenuNameMinLength = "メニュー名は{0}文字以上で入力してください";
  static const String validationMenuNameMaxLength = "メニュー名は{0}文字以下で入力してください";
  static const String validationMenuNameInvalidChars = "メニュー名に使用できない文字が含まれています";
  static const String validationMenuNameWhitespace = "メニュー名の前後に空白文字は入力できません";

  static const String validationCustomerNameRequired = "顧客名は必須です";
  static const String validationCustomerNameMinLength = "顧客名は{0}文字以上で入力してください";
  static const String validationCustomerNameMaxLength = "顧客名は{0}文字以下で入力してください";
  static const String validationCustomerNameInvalidChars = "顧客名に使用できない文字が含まれています";

  static const String validationEmailRequired = "メールアドレスは必須です";
  static const String validationEmailInvalidFormat = "メールアドレスの形式が正しくありません";

  static const String validationPasswordRequired = "パスワードは必須です";
  static const String validationPasswordMinLength = "パスワードは8文字以上で入力してください";
  static const String validationPasswordComplexity = "パスワードは大文字、小文字、数字を含む必要があります";

  static const String validationUrlRequired = "URLは必須です";
  static const String validationUrlInvalidFormat = "有効なURLを入力してください";

  static const String validationDateRequired = "日付は必須です";
  static const String validationDateInvalidFormat = "日付の形式が正しくありません";
  static const String validationDateMinDate = "日付は{0}以降を入力してください";
  static const String validationDateMaxDate = "日付は{0}以前を入力してください";

  static const String validationTotalAmountExceeded = "合計金額が上限（{0}円）を超えています";

  // ======================== text ========================
  static const String textNotApplicable = "N/A";
  static const String textLogin = "ログイン";
  static const String textAuthenticating = "認証中...";
  static const String textDeveloperInfo = "開発者向け情報";
  static const String textSupabaseEnvInfo = "Supabase認証が設定されていない場合、\n環境変数(.env)を確認してください";
  static const String textCartEmpty = "カートが空です";
  static const String textSelectFromMenu = "メニューからアイテムを選択してください";
  static const String textClearCart = "カートをクリア";
  static const String textUserInfoNotAvailable = "ユーザー情報が取得できません";
  static const String textErrorOccurred = "エラーが発生しました";
  static const String textNoData = "データがありません";
  static const String textProductCategory = "商品カテゴリー";
}
