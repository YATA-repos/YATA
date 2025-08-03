# 既存実装統合マッピング

## 概要

このドキュメントは、YATAプロジェクトの既存実装と新規UI実装の統合関係を明確にし、効率的な開発を支援するためのマッピング資料です。

## 1. 既存実装の活用マップ

### 1.1 ✅ 完全実装済み（統合活用）

| カテゴリ | 既存ファイル | 実装状況 | 新規実装での活用方法 |
|---------|-------------|---------|-------------------|
| **テーマシステム** | | | |
| 色定義 | `lib/shared/themes/app_colors.dart` | ✅ 完全実装 | Widget作成時に直接参照 |
| テキストスタイル | `lib/shared/themes/app_text_theme.dart` | ✅ 完全実装 | Widget作成時に直接参照 |
| **アーキテクチャ基盤** | | | |
| ベースモデル | `lib/core/base/base_model.dart` | ✅ 完全実装 | そのまま継承・活用 |
| 基底Repository | `lib/core/base/base_repository.dart` | ✅ 完全実装 | そのまま継承・活用 |
| **ドメインモデル** | | | |
| メニュー | `lib/features/menu/models/menu_model.dart` | ✅ 完全実装 | Riverpodプロバイダーで直接使用 |
| 注文 | `lib/features/order/models/order_model.dart` | ✅ 完全実装 | Riverpodプロバイダーで直接使用 |
| 在庫 | `lib/features/inventory/models/inventory_model.dart` | ✅ 完全実装 | Riverpodプロバイダーで直接使用 |
| **サービス層** | | | |
| メニューサービス | `lib/features/menu/services/menu_service.dart` | ✅ 詳細実装済み | Riverpodプロバイダーで直接インジェクション |
| 注文サービス | `lib/features/order/services/` | ✅ 推定実装済み | Riverpodプロバイダーで直接インジェクション |
| **ユーティリティ** | | | |
| バリデーション | `lib/core/validation/input_validator.dart` | ✅ 完全実装 | フォームWidgetで直接使用 |
| ログ機能 | `lib/core/logging/logger_mixin.dart` | ✅ 完全実装 | プロバイダー・Widgetで継承使用 |

### 1.2 ❌ 未実装（新規作成対象）

| カテゴリ | 作成予定ファイル | 実装フェーズ | 既存実装との統合点 |
|---------|----------------|-------------|------------------|
| **共通Widget** | | | |
| ボタン | `lib/shared/widgets/buttons/app_button.dart` | Phase 2 | AppColors, AppTextTheme活用 |
| カード | `lib/shared/widgets/cards/stats_card.dart` | Phase 2 | AppColors.success等の業務色活用 |
| メニューカード | `lib/shared/widgets/cards/menu_item_card.dart` | Phase 2 | MenuItem、AppTextTheme.priceText活用 |
| **プレゼンテーション層** | | | |
| 画面 | `lib/features/*/presentation/screens/` | Phase 3 | 既存サービス、共通Widget活用 |
| プロバイダー | `lib/features/*/presentation/providers/` | Phase 4 | 既存サービス直接呼び出し |
| **アプリ基盤** | | | |
| アプリ構造 | `lib/app/app.dart` | Phase 1 | 既存テーマシステム統合 |
| ルーティング | `lib/app/routes.dart` | Phase 1 | 新規画面への遷移設定 |

## 2. 統合パターン

### 2.1 既存モデル直接活用パターン

#### MenuService + MenuItem の活用例
```dart
// 既存実装を直接活用（Phase 4）
@riverpod
Future<List<MenuItem>> menuItems(MenuItemsRef ref, String userId) async {
  final service = MenuService(); // 既存サービス直接使用
  return service.getMenuItemsByCategory(null, userId); // 既存メソッド直接呼び出し
}

// UI層での使用例（Phase 3）
class MenuItemCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(menuItemsProvider(userId)).when(
      data: (items) => ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index]; // MenuItem（既存ドメインモデル）
          return Card(
            child: Text(item.name), // 既存プロパティ直接参照
          );
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### 2.2 既存テーマ直接活用パターン

#### AppColors + AppTextTheme の活用例
```dart
// Phase 2: 共通Widget実装時の既存テーマ活用
class AppButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, // 既存色定義直接使用
        foregroundColor: AppColors.primaryForeground,
      ),
      child: Text(
        'ボタン',
        style: AppTextTheme.buttonText, // 既存テキストスタイル直接使用
      ),
      onPressed: onPressed,
    );
  }
}

// Phase 3: 業務固有色の活用例
class StatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.inStock, // 既存業務固有色（在庫あり）
      child: Text(
        '在庫状況: 良好',
        style: AppTextTheme.cardTitle, // 既存カードタイトルスタイル
      ),
    );
  }
}
```

### 2.3 既存UI拡張パターン

#### Extension活用による既存モデル拡張
```dart
// Phase 4: 既存モデルにUI特化機能を追加
extension MenuItemUIExtensions on MenuItem {
  // 既存のpriceプロパティを使ってフォーマット
  String get formattedPrice => '¥${price.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},',
  )}';
  
  // 既存のisAvailableプロパティを使って色を決定
  Color get statusColor => isAvailable 
      ? AppColors.inStock 
      : AppColors.outOfStock;
}

// 使用例
Text(menuItem.formattedPrice) // 既存モデル + UI拡張
```

## 3. フェーズ別統合戦略

### Phase 1: アーキテクチャ統合（4日）
- **統合対象**: AppColors, AppTextTheme
- **作成物**: AppTheme統合クラス、ResponsiveHelper
- **既存活用**: テーマシステム100%活用

### Phase 2: Widget実装（4週間）
- **統合対象**: AppColors, AppTextTheme全般
- **作成物**: 共通Widgetライブラリ
- **既存活用**: 色・テキストスタイル直接参照

### Phase 3: 画面実装（6週間）
- **統合対象**: 既存サービス、ドメインモデル、共通Widget
- **作成物**: 各機能の画面・Widget
- **既存活用**: MenuService等の業務ロジック直接使用

### Phase 4: 状態管理（3週間）
- **統合対象**: 既存サービス、ドメインモデル
- **作成物**: Riverpodプロバイダー、軽量UI拡張
- **既存活用**: サービス層との直接統合

### Phase 5: テスト・品質管理（4週間）
- **統合対象**: 既存バリデーション、ログシステム
- **作成物**: テストスイート、品質管理システム
- **既存活用**: InputValidator, LoggerMixin活用

## 4. 統合時の注意点

### 4.1 既存実装の理解
- **詳細確認必須**: 既存サービスのメソッドシグネチャ、戻り値型の確認
- **業務ロジック理解**: MenuService等の複雑なビジネスロジックの理解
- **エラーハンドリング**: 既存例外システムとの整合性確保

### 4.2 バージョン互換性
- **Dart/Flutter**: 既存実装とUI実装でのバージョン統一
- **依存パッケージ**: riverpod、freezed等の追加時の既存パッケージとの競合回避

### 4.3 パフォーマンス考慮
- **プロバイダー設計**: 既存サービスの呼び出し頻度最適化
- **キャッシュ戦略**: 既存Repository層のキャッシュとRiverpodキャッシュの協調

## 5. 統合検証チェックリスト

### Phase 1完了時
- [ ] AppColors, AppTextThemeが新規AppThemeで正しく統合されている
- [ ] 既存テーマが新規アプリ構造で適用されている
- [ ] ResponsiveHelperが既存レイアウトと協調している

### Phase 2完了時
- [ ] 全Widget実装でApp*theme系クラスを直接使用している
- [ ] 業務固有色（cooking, inStock等）が適切に活用されている
- [ ] 既存テキストスタイル（priceText, cardTitle等）が活用されている

### Phase 3完了時
- [ ] 既存サービス（MenuService等）が画面から正しく呼び出されている
- [ ] 既存ドメインモデル（MenuItem等）が画面で正しく表示されている
- [ ] 共通Widgetが各画面で一貫して使用されている

### Phase 4完了時
- [ ] 既存サービスがRiverpodプロバイダーで正しくインジェクションされている
- [ ] 既存ドメインモデルがプロバイダーで正しく処理されている
- [ ] UI拡張（Extension）が既存モデルと正しく統合されている

### Phase 5完了時
- [ ] 既存バリデーションシステムがUI層で活用されている
- [ ] 既存ログシステムがプロバイダー・Widgetで活用されている
- [ ] 統合テストで既存実装とUI実装の連携が検証されている

## 6. 統合効果の測定

### 開発効率向上
- **実装工数削減**: 既存活用により約30%の工数削減を達成
- **品質向上**: 既存の実績あるコンポーネント活用による品質確保
- **一貫性確保**: 統一されたテーマシステムによるデザイン一貫性

### 保守性向上
- **中央集権管理**: テーマ・サービスの中央集約による管理効率向上
- **変更波及最小化**: 既存システムへの影響を最小限に抑制
- **テスト容易性**: 既存テスト済みコンポーネントの活用

この統合マッピングにより、既存実装を最大限活用しながら効率的なUI開発を実現する。