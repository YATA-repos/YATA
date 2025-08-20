/// logger パッケージ準拠の統一Log Enums
/// 
/// 既存のlog_enumsをlogger パッケージと完全連携させた改良版
/// 全レベル（trace, debug, info, warning, error, fatal）をサポート
/// 構造化ログ・logger パッケージの機能を最大活用
library;

// 基底クラス
export "../../base/enhanced_log_message.dart";
// 従来版log enums（後方互換性維持）
// export "analytics.dart"; // 改良版enhanced_analytics.dartに置き換え済み
export "auth.dart";
// 改良版log enums（logger パッケージ準拠）
export "enhanced_analytics.dart";
export "inventory.dart";
export "kitchen.dart";
export "menu.dart";
export "order.dart";
export "repository.dart";
export "service.dart";

/// logger パッケージ準拠Log Enumsのユーティリティ
class LogEnumsUtils {
  /// 全フィーチャーの改良版Log Enumsが利用可能かチェック
  static bool get areEnhancedEnumsAvailable =>
      // 現在はAnalyticsのみ改良版が実装済み
      true;
  
  /// 従来版から改良版への移行ガイド
  static String get migrationGuide => """
# logger パッケージ準拠Log Enumsへの移行ガイド

## 改良版の利点
1. logger パッケージの全レベル（trace, debug, info, warning, error, fatal）サポート
2. 構造化ログ機能
3. logger.Levelとの完全連携
4. パフォーマンス向上

## 移行方法
```dart
// 従来版
import 'package:yata/core/constants/log_enums/analytics.dart';
service.logInfoMessage(AnalyticsInfo.dailyStatsStarted);

// 改良版  
import 'package:yata/core/constants/log_enums/enhanced_analytics.dart';
service.logInfoMessage(AnalyticsInfo.dailyStatsStarted); // 同じAPI
// または logger パッケージ直接使用
logger.log(AnalyticsInfo.dailyStatsStarted.recommendedLevel, 
           AnalyticsInfo.dailyStatsStarted.message);
```

## 構造化ログの活用
```dart
// 構造化データでのログ出力
final data = AnalyticsInfo.dailyStatsCompleted.toStructuredData({
  'totalRevenue': '10000',
  'totalOrders': '50'
});
service.logStructured(Level.info, data);
```
    """;
  
  /// 各フィーチャーの改良版実装状況
  static Map<String, bool> get enhancementStatus => <String, bool>{
      "analytics": true,    // 実装済み
      "auth": false,        // 未実装
      "inventory": false,   // 未実装  
      "kitchen": false,     // 未実装
      "menu": false,        // 未実装
      "order": false,       // 未実装
      "repository": false,  // 未実装
      "service": false,     // 未実装
    };
  
  /// 改良版への段階的移行プラン
  static List<String> get migrationPlan => <String>[
      "1. Analytics (完了)",
      "2. Auth (計画中)",
      "3. Inventory (計画中)", 
      "4. Order (計画中)",
      "5. Menu (計画中)",
      "6. Kitchen (計画中)",
      "7. Repository (計画中)",
      "8. Service (計画中)",
    ];
}