enum ButtonVariant {
  primary, // 緑色（完了、確定用）
  secondary, // 青色（編集、詳細用）
  warning, // 黄色（調理中、警告用）
  danger, // 赤色（削除、キャンセル用）
  ghost, // 透明（サブアクション用）
}

enum ButtonSize { small, medium, large }

enum CardVariant {
  basic, // 基本白カード
  highlighted, // 背景色付き
  outlined, // 枠線のみ
}

enum InputVariant {
  standard, // 通常入力
  search, // 検索（アイコン付き）
  number, // 数値入力
}

enum BadgeVariant {
  success, // 緑（完了、在庫あり）
  warning, // 黄（注意、在庫少）
  danger, // 赤（警告、期限切れ）
  info, // 青（情報）
  count, // 数値表示用
}

enum IconButtonVariant {
  standard,
  floating, // FAB用
  navigation, // ナビゲーション用
}

enum ChipVariant {
  basic, // 基本チップ
  outlined, // アウトライン
  success, // 成功（緑）
  warning, // 警告（黄）
  danger, // 危険（赤）
}

enum ChipSize { small, medium, large }

enum IconPosition {
  leading, // アイコンを左に配置
  trailing, // アイコンを右に配置
}

enum DropdownVariant {
  standard, // 通常のドロップダウン
  outlined, // アウトライン
  filled, // 背景色付き
}

enum TabBarVariant {
  standard, // 通常のタブバー
  underlined, // アンダーライン付き
  pills, // ピル型
  contained, // 背景付き
}

enum DatePickerVariant {
  standard, // 通常の日付選択
  range, // 範囲選択
  compact, // コンパクト表示
}

enum SearchBarVariant {
  standard, // 通常の検索バー
  compact, // コンパクト
  bordered, // 枠線付き
}

enum LoadingIndicatorVariant {
  circular, // 円形
  linear, // 線形
  dots, // ドット
  spinner, // スピナー
}

enum LoadingIndicatorSize {
  small, // 小
  medium, // 中
  large, // 大
}
