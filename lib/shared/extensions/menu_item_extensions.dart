import "package:flutter/material.dart";

import "../../features/menu/models/menu_model.dart";
import "../themes/app_colors.dart";

/// MenuItem UI拡張
/// 既存のMenuItemモデルにUI表示用の拡張メソッドを追加
/// 新規モデル作成ではなく、拡張によるアプローチを採用
extension MenuItemUIExtensions on MenuItem {
  /// UI表示用の価格フォーマット
  /// 日本円表記でカンマ区切りに整形
  String get formattedPrice {
    final String formattedNumber = price.toString().replaceAllMapped(
      RegExp(r"(\d)(?=(\d{3})+(?!\d))"),
      (Match match) => "${match[1]},",
    );
    return "¥$formattedNumber";
  }

  /// 在庫状況に応じたステータス色
  /// isAvailableフラグに基づいて適切な色を返す
  Color get stockStatusColor => isAvailable ? AppColors.inStock : AppColors.outOfStock;

  /// 在庫状況のテキスト表示
  /// 日本語での在庫状況説明
  String get stockStatusText => isAvailable ? "販売中" : "品切れ";

  /// UI表示用の説明文
  /// nullの場合のフォールバック処理付き
  String get displayDescription => description ?? "説明なし";

  /// 調理時間の表示文字列
  /// 分単位での表示（例：「約15分」）
  String get prepTimeDisplay => "約$estimatedPrepTimeMinutes分";

  /// 調理時間に応じた色分け
  /// 調理時間の長さに応じて色を変更
  Color get prepTimeColor {
    if (estimatedPrepTimeMinutes <= 10) {
      return AppColors.success; // 10分以内：緑
    } else if (estimatedPrepTimeMinutes <= 20) {
      return AppColors.warning; // 20分以内：黄色
    } else {
      return AppColors.danger; // 20分超：赤
    }
  }

  /// 在庫アラート表示の必要性
  /// 在庫切れの場合にアラート表示するかどうか
  bool get needsStockAlert => !isAvailable;

  /// 価格帯カテゴリー
  /// 価格に応じたカテゴリー分類
  String get priceCategory {
    if (price < 500) {
      return "低価格";
    } else if (price < 1000) {
      return "中価格";
    } else {
      return "高価格";
    }
  }

  /// 価格帯に応じた色
  /// 価格カテゴリーに対応した色分け
  Color get priceCategoryColor {
    if (price < 500) {
      return AppColors.success;
    } else if (price < 1000) {
      return AppColors.warning;
    } else {
      return AppColors.primary;
    }
  }

  /// 人気度表示用のアイコン
  /// 価格や調理時間から算出した人気度指標
  IconData get popularityIcon {
    // 低価格かつ短時間調理のものを人気と仮定
    if (price < 800 && estimatedPrepTimeMinutes <= 15) {
      return Icons.star;
    } else if (price < 1200 && estimatedPrepTimeMinutes <= 20) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  /// おすすめ度の色
  /// 人気度に応じた色分け
  Color get popularityColor {
    if (price < 800 && estimatedPrepTimeMinutes <= 15) {
      return AppColors.warning; // 金色っぽい
    } else if (price < 1200 && estimatedPrepTimeMinutes <= 20) {
      return AppColors.secondary;
    } else {
      return AppColors.mutedForeground;
    }
  }

  /// カード表示用のサブタイトル
  /// 価格と調理時間を組み合わせた表示
  String get cardSubtitle => "$formattedPrice • $prepTimeDisplay";

  /// リスト表示用の詳細情報
  /// より詳細な情報を1行で表示
  String get listDetailText => "$formattedPrice • $prepTimeDisplay • $stockStatusText";

  /// 検索用のキーワード文字列
  /// 名前と説明文を結合した検索対象文字列
  String get searchKeywords => "${name.toLowerCase()} ${displayDescription.toLowerCase()}";

  /// フィルタリング用の表示順序重み
  /// ソート時に使用する重み値（小さいほど上位）
  int get displayWeight {
    int weight = 0;

    // 在庫あり優先
    if (isAvailable) {
      weight += 1000;
    }

    // 価格による重み付け（安いほど上位）
    weight += price ~/ 100;

    // 調理時間による重み付け（短いほど上位）
    weight += estimatedPrepTimeMinutes;

    return weight;
  }

  /// アクセシビリティ用のセマンティクスラベル
  /// スクリーンリーダー対応のラベル文字列
  String get semanticsLabel => "メニュー: $name, 価格: $formattedPrice, 調理時間: $prepTimeDisplay, 状態: $stockStatusText";
}
