/// バッジバリアント
enum BadgeVariant {
  default_, // デフォルト
  primary, // プライマリ
  secondary, // セカンダリ
  success, // 成功
  warning, // 警告
  danger, // 危険
  // 業務固有バリアント
  cooking, // 調理中
  complete, // 完了
  inStock, // 在庫あり
  lowStock, // 在庫少
  outOfStock, // 在庫切れ
}

/// バッジサイズ
enum BadgeSize {
  small, // 小
  medium, // 中
  large, // 大
}

/// ボタンバリアント
enum ButtonVariant {
  primary,
  secondary,
  outline,
  danger,
  // 業務固有バリアント
  complete, // 完了・確定
  cooking, // 調理中・注意
  cancel, // キャンセル・削除
}

/// ボタンサイズ
enum ButtonSize { small, medium, large }

/// カードバリアント
enum CardVariant {
  default_, // デフォルト
  elevated, // 高いエレベーション
  outlined, // アウトライン強調
  muted, // 控えめ表示
  primary, // プライマリ色
  success, // 成功状態
  warning, // 警告状態
  danger, // 危険状態
}

/// メニューカードバリアント
enum MenuCardVariant {
  default_, // デフォルト
  compact, // コンパクト
  detailed, // 詳細表示
}

/// 統計カードバリアント
enum StatsCardVariant {
  default_, // デフォルト
  success, // 成功
  warning, // 警告
  danger, // 危険
  info, // 情報
  // 業務固有バリアント
  stock, // 在庫関連
  lowStock, // 低在庫
  sales, // 売上関連
}

/// トレンド方向
enum TrendDirection {
  up, // 上昇
  down, // 下降
  neutral, // 変化なし
}

/// カテゴリフィルターバリアント
enum CategoryFilterVariant {
  chips, // チップ表示
  list, // リスト表示
  grid, // グリッド表示
  dropdown, // ドロップダウン表示
}

/// 検索フィールドバリアント
enum SearchFieldVariant {
  standard, // 標準（フィルター付き）
  filled, // 塗りつぶし
  compact, // コンパクト（フィルターなし）
}

/// テキストフィールドバリアント
enum TextFieldVariant {
  outlined, // アウトライン
  filled, // 塗りつぶし
  underlined, // アンダーライン
}

/// ローディングサイズ列挙型
enum LoadingSize { small, medium, large }

/// モードセレクターバリアント
enum ModeSelectorVariant {
  segmented, // セグメント型
  tabs, // タブ型
  buttons, // ボタン型
}
