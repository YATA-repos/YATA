# YATAプロジェクト バックエンド層テスト実装計画書

## 概要

YATAプロジェクトのバックエンド部分（Repository層とServices層）に対する包括的なUnit TestsとIntegration Testsの実装計画書。本計画は実装の安定性向上、バグの早期発見、リファクタリングの安全性確保を目的とする。

---

## 1. 現状分析

### 1.1 プロジェクト状況
- **アーキテクチャ**: フィーチャーベース・サービスレイヤーアーキテクチャ
- **主要技術**: Flutter, Riverpod, Supabase, Decimal
- **テスト環境**: 現在未整備（testディレクトリ未存在）
- **テスト依存関係**: flutter_test, integration_test（pubspec.yamlに設定済み）

### 1.2 バックエンド層の実装状況

#### Repository層（8ファイーチャー、32クラス）
```
features/
├── analytics/repositories/     (1クラス)
├── auth/repositories/          (1クラス)  
├── inventory/repositories/     (8クラス) ★最重要
├── menu/repositories/          (2クラス)
└── order/repositories/         (2クラス)

core/base/
├── BaseRepository<T, ID>       ★基盤クラス
└── BaseMultiTenantRepository<T, ID> ★基盤クラス
```

#### Services層（8フィーチャー、22クラス）
```
features/
├── analytics/services/         (1クラス)
├── auth/services/             (1クラス)
├── inventory/services/        (8クラス) ★最複雑
├── menu/services/             (1クラス)
└── order/services/            (9クラス) ★高複雑
```

#### Core層（89ファイル、9モジュール）★新規追加
```
core/
├── base/                      (6クラス) ★既存計画済み
├── cache/                     (7クラス) ★S級重要度
├── constants/                 (32クラス) ★例外・列挙型
├── infrastructure/            (1クラス) ★Supabase統合
├── logging/                   (10クラス) ★S級重要度  
├── providers/                 (12クラス) ★A級重要度
├── realtime/                  (4クラス) ★A級重要度
├── services/                  (1クラス) ★バッチ処理
└── validation/                (3クラス) ★B級重要度
```

### 1.3 テスト実装の課題

#### 技術的課題
1. **強い外部依存**: Supabaseクライアント直接使用
2. **静的メソッド**: QueryUtilsの差し替え困難性
3. **複合依存関係**: 複数サービス間の複雑な関係
4. **リアルタイム機能**: WebSocket依存の機能群

#### アーキテクチャ課題
1. **テスタビリティ設計不足**: DI抽象化の部分的実装
2. **モック化困難**: 基盤クラスの外部依存
3. **統合テスト環境**: Supabase test instance未設定

---

## 2. テスト戦略

### 2.1 テストピラミッド設計

```
                  🔺
                 /  \
           Integration \     (20%) - 主要業務フロー
              /--------\
             /  Unit    \   (80%) - 個別機能検証
            /------------\
```

### 2.2 テスト分類と責任範囲

#### Unit Tests（単体テスト）
- **対象**: Repository個別メソッド、Services個別機能
- **目的**: 機能の正確性、エラーハンドリング、境界値検証
- **実行**: 毎回のビルド時、CI/CD pipeline
- **カバレッジ目標**: 90%以上

#### Integration Tests（統合テスト）
- **対象**: Repository↔Database、Services↔Repository連携
- **目的**: データフロー、業務プロセス、システム連携検証
- **実行**: リリース前、夜間バッチ
- **カバレッジ目標**: 主要フロー100%

### 2.3 テスト優先度マトリックス（Core層統合版）

| 分類 | クラス名 | 複雑度 | ビジネス影響 | 優先度 | 理由 |
|------|----------|--------|--------------|--------|------|
| **基盤** | BaseRepository | 高 | 最高 | **P0** | 全Repository操作の基盤 |
| **基盤** | BaseMultiTenantRepository | 高 | 最高 | **P0** | セキュリティクリティカル |
| **Core/Logging** | YataLoggerService | 高 | 最高 | **P0** | 全システムログ基盤 |
| **Core/Cache** | CacheManager | 高 | 高 | **P0** | システム性能の要 |
| **Services** | InventoryService | 最高 | 最高 | **P0** | 最複雑、リアルタイム機能 |
| **Core/Providers** | CommonProviders | 中 | 高 | **P1** | Riverpod状態管理基盤 |
| **Core/Realtime** | RealtimeManager | 高 | 高 | **P1** | リアルタイム機能基盤 |
| **Services** | OrderWorkflowService | 高 | 高 | **P1** | 発注アルゴリズム |
| **Services** | AuthService | 中 | 高 | **P1** | 認証・セッション管理 |
| **Utility** | QueryUtils | 中 | 高 | **P1** | 全Repository操作に影響 |
| **Core/Validation** | TypeValidator | 中 | 中 | **P2** | 型安全性確保 |
| **Core/Infrastructure** | SupabaseClient | 低 | 中 | **P2** | DB接続ラッパー |
| **Repository** | MaterialRepository | 低 | 中 | **P2** | 標準的なCRUD |

---

## 3. Unit Tests実装計画

### 3.1 基盤クラステスト

#### BaseRepository<T, ID> テスト
**ファイル**: `test/core/base/base_repository_test.dart`

```dart
group('BaseRepository Tests', () {
  // 基本CRUD操作
  test('create() - 正常系');
  test('create() - バリデーションエラー');
  test('create() - 重複キーエラー');
  
  // 複合主キー処理
  test('findById() - 単一キー');
  test('findById() - 複合キー');
  test('findById() - 不正なキー形式');
  
  // クエリ構築
  test('findAll() - フィルタなし');
  test('findAll() - 複数条件フィルタ');
  test('findAll() - ソート条件');
  test('findAll() - ページネーション');
  
  // エラーハンドリング
  test('handleDatabaseError() - 接続エラー');
  test('handleDatabaseError() - SQL構文エラー');
  test('handleDatabaseError() - 権限エラー');
});
```

#### BaseMultiTenantRepository テスト
**ファイル**: `test/core/base/base_multitenant_repository_test.dart`

```dart
group('BaseMultiTenantRepository Tests', () {
  // マルチテナント機能
  test('findAll() - 自動user_idフィルタリング');
  test('findById() - 他ユーザーデータアクセス拒否');
  test('update() - 他ユーザーデータ更新拒否');
  test('delete() - 他ユーザーデータ削除拒否');
  
  // 認証状態処理
  test('未認証状態でのアクセス拒否');
  test('セッション期限切れ処理');
  
  // 管理者機能
  test('findAllWithoutFilter() - 管理者権限');
  test('管理者権限なしでのアクセス拒否');
});
```

### 3.2 主要Servicesテスト

#### InventoryService テスト
**ファイル**: `test/features/inventory/services/inventory_service_test.dart`

```dart
group('InventoryService Tests', () {
  // 統合機能
  test('getInventoryOverview() - 正常系');
  test('getInventoryOverview() - データなし状態');
  
  // リアルタイム機能
  test('リアルタイム監視開始・停止');
  test('リアルタイムデータ更新処理');
  test('接続断絶時の再接続処理');
  
  // 複数サービス連携
  test('材料管理との連携');
  test('在庫レベルサービスとの連携');
  test('発注ワークフローとの連携');
  
  // パフォーマンス
  test('大量データ処理のパフォーマンス');
  test('同時アクセス時の動作');
});
```

#### OrderWorkflowService テスト
**ファイル**: `test/features/inventory/services/order_workflow_service_test.dart`

```dart
group('OrderWorkflowService Tests', () {
  // 発注提案アルゴリズム
  test('calculateOrderSuggestions() - 標準ケース');
  test('calculateOrderSuggestions() - 在庫ゼロケース');
  test('calculateOrderSuggestions() - 季節変動考慮');
  
  // 閾値計算
  test('安全在庫レベル計算');
  test('リードタイム考慮計算');
  test('需要予測アルゴリズム');
  
  // エッジケース
  test('異常データでの計算安定性');
  test('計算タイムアウト処理');
});
```

### 3.3 ユーティリティテスト

#### QueryUtils テスト
**ファイル**: `test/core/utils/query_utils_test.dart`

```dart
group('QueryUtils Tests', () {
  // フィルタ構築
  test('applyFilter() - 単一条件');
  test('applyFilter() - 複数条件 AND');
  test('applyFilter() - 複数条件 OR');
  test('applyFilter() - ネストした条件');
  
  // ソート構築
  test('applySorting() - 単一カラム');
  test('applySorting() - 複数カラム');
  test('applySorting() - 昇順・降順');
  
  // ページネーション
  test('applyPagination() - 標準ケース');
  test('applyPagination() - 境界値');
  
  // バリデーション
  test('不正なフィルタ値の検証');
  test('SQLインジェクション対策');
});
```

### 3.4 モック化戦略

#### Supabaseクライアント
```dart
class MockSupabaseClient extends Mock implements SupabaseClient {
  // 必要なメソッドのモック実装
}

// テストセットアップ
setUp(() {
  when(mockSupabaseClient.from('table_name'))
      .thenReturn(mockPostgrestBuilder);
});
```

#### Repository層
```dart
class MockMaterialRepository extends Mock implements MaterialRepository {}
class MockSupplierRepository extends Mock implements SupplierRepository {}

// Services層テスト用
final mockMaterialRepo = MockMaterialRepository();
final mockSupplierRepo = MockSupplierRepository();
```

### 3.5 Core層テスト実装計画

#### 3.5.1 Loggingシステムテスト（P0優先度）

##### YataLoggerService テスト
**ファイル**: `test/core/logging/yata_logger_service_test.dart`

```dart
group('YataLoggerService Tests', () {
  // Singleton パターンテスト
  test('getInstance() - Singleton確認');
  test('複数getInstance()で同一インスタンス確認');
  
  // ログレベル制御
  test('setLogLevel() - 動的レベル変更');
  test('isLoggable() - レベル別出力制御');
  
  // 環境別出力制御
  test('開発環境 - コンソール出力確認');
  test('本番環境 - ファイル出力確認');
  test('テスト環境 - 出力抑制確認');
  
  // パフォーマンス統計
  test('パフォーマンス統計収集');
  test('統計リセット機能');
  
  // バッファリング機能
  test('バッファサイズ制御');
  test('フラッシュタイミング制御');
  
  // エラーハンドリング
  test('ログ出力エラー時の安全性確保');
  test('ディスク容量不足時の処理');
});
```

##### LoggerMixin統合テスト
**ファイル**: `test/core/logging/logger_mixin_test.dart`

```dart
group('LoggerMixin Tests', () {
  // 複数バージョン互換性
  test('UnifiedLoggerMixin使用時の動作');
  test('従来LoggerMixin使用時の動作');
  
  // 事前定義メッセージ
  test('logInfo() - 構造化メッセージ');
  test('logError() - エラー情報含有');
  test('logDebug() - デバッグ情報');
  
  // コンテキスト情報
  test('クラス名自動取得');
  test('メソッド名自動取得');
});
```

#### 3.5.2 キャッシュシステムテスト（P0優先度）

##### CacheManager テスト
**ファイル**: `test/core/cache/cache_manager_test.dart`

```dart
group('CacheManager Tests', () {
  // 基本キャッシュ操作
  test('set() - 値設定');
  test('get() - 値取得');
  test('delete() - 値削除'); 
  test('clear() - 全削除');
  
  // TTL機能
  test('TTL期限切れ自動削除');
  test('TTL更新機能');
  
  // メモリ管理
  test('メモリ上限制御');
  test('LRU削除アルゴリズム');
  
  // キャッシュ戦略
  test('Write-Through戦略');
  test('Write-Behind戦略');
  test('Cache-Aside戦略');
  
  // パフォーマンス
  test('大量データでの性能');
  test('同時アクセス時の整合性');
});
```

##### RepositoryCacheMixin テスト
**ファイル**: `test/core/cache/repository_cache_mixin_test.dart`

```dart
group('RepositoryCacheMixin Tests', () {
  // Repository統合
  test('findWithCache() - キャッシュ有効活用');
  test('updateWithCache() - キャッシュ無効化');
  test('deleteWithCache() - 関連キャッシュ削除');
  
  // キャッシュキー生成
  test('generateCacheKey() - 一意性確保');
  test('複合キーでのキャッシュキー生成');
  
  // 無効化戦略
  test('タグベース無効化');
  test('時間ベース無効化');
});
```

#### 3.5.3 Providersシステムテスト（P1優先度）

##### CommonProviders テスト
**ファイル**: `test/core/providers/common_providers_test.dart`

```dart
group('CommonProviders Tests', () {
  late ProviderContainer container;
  
  setUp(() {
    container = ProviderContainer();
  });
  
  // 基本Provider機能
  test('supabaseClientProvider - クライアント取得');
  test('loggerServiceProvider - ログサービス取得');
  test('cacheManagerProvider - キャッシュマネージャー取得');
  
  // 依存関係注入
  test('Provider間の依存関係確認');
  test('循環依存の検出・回避');
  
  // ライフサイクル管理
  test('Providerの初期化順序');
  test('Providerの破棄処理');
  
  // エラーハンドリング
  test('Provider初期化失敗時の処理');
  test('依存Provider不在時の処理');
});
```

##### RealtimeProviders テスト
**ファイル**: `test/core/providers/realtime_providers_test.dart`

```dart
group('RealtimeProviders Tests', () {
  // リアルタイム接続管理
  test('connectionManagerProvider - 接続状態管理');
  test('realtimeConfigProvider - 設定管理');
  
  // 状態同期
  test('リアルタイムデータ同期');
  test('接続断絶時の状態維持');
  test('再接続時のデータ整合性');
  
  // パフォーマンス
  test('大量リアルタイムデータでの性能');
  test('メモリリーク防止');
});
```

#### 3.5.4 リアルタイム機能テスト（P1優先度）

##### RealtimeManager テスト
**ファイル**: `test/core/realtime/realtime_manager_test.dart`

```dart
group('RealtimeManager Tests', () {
  // 接続管理
  test('connect() - 正常接続');
  test('connect() - 接続失敗時の処理');
  test('disconnect() - 安全な切断');
  test('reconnect() - 自動再接続');
  
  // チャンネル管理
  test('subscribeChannel() - チャンネル購読');
  test('unsubscribeChannel() - 購読解除');
  test('複数チャンネル同時管理');
  
  // データ受信処理
  test('onMessage() - メッセージ受信処理');
  test('onError() - エラーメッセージ処理');
  test('onClose() - 接続終了処理');
  
  // 状態管理
  test('接続状態の正確な追跡');
  test('エラー状態からの復旧');
});
```

##### ConnectionManager テスト
**ファイル**: `test/core/realtime/connection_manager_test.dart`

```dart
group('ConnectionManager Tests', () {
  // WebSocket接続
  test('WebSocket接続確立');
  test('接続品質監視');
  test('ハートビート機能');
  
  // 再接続戦略
  test('指数バックオフ再接続');
  test('最大再接続回数制御');
  test('手動再接続機能');
  
  // エラー処理
  test('ネットワークエラー処理');
  test('タイムアウト処理');
  test('サーバーエラー処理');
});
```

#### 3.5.5 バリデーション機能テスト（P2優先度）

##### TypeValidator テスト
**ファイル**: `test/core/validation/type_validator_test.dart`

```dart
group('TypeValidator Tests', () {
  // 型検証
  test('validateType() - 正常な型');
  test('validateType() - 不正な型');
  test('validateNullable() - null許可型');
  
  // ID検証
  test('validateId() - 単一キー');
  test('validateId() - 複合キー');
  test('validateId() - 不正なキー形式');
  
  // カスタム検証
  test('custom validator登録・実行');
  test('validator chain実行');
  
  // エラーメッセージ
  test('詳細なエラーメッセージ生成');
  test('多言語対応エラーメッセージ');
});
```

##### InputValidator テスト
**ファイル**: `test/core/validation/input_validator_test.dart`

```dart
group('InputValidator Tests', () {
  // 基本検証
  test('required() - 必須項目検証');
  test('length() - 文字列長検証');
  test('range() - 数値範囲検証');
  test('pattern() - 正規表現検証');
  
  // 業務固有検証
  test('email() - メールアドレス検証');
  test('phone() - 電話番号検証');
  test('currency() - 通貨値検証');
  
  // 複合検証
  test('複数条件AND検証');
  test('複数条件OR検証');
  test('条件付き検証（dependent validation）');
});
```

#### 3.5.6 Core層モック化戦略

##### Singletonクラスのモック化
```dart
// Logger Service
class MockYataLoggerService extends Mock implements YataLoggerService {
  static MockYataLoggerService? _mockInstance;
  
  static MockYataLoggerService getMockInstance() {
    return _mockInstance ??= MockYataLoggerService();
  }
}

// テストセットアップ
setUp(() {
  YataLoggerService.setTestInstance(MockYataLoggerService.getMockInstance());
});
```

##### Riverpod Providerのオーバーライド
```dart
// Provider テスト用オーバーライド
final testContainer = ProviderContainer(
  overrides: [
    supabaseClientProvider.overrideWithValue(mockSupabaseClient),
    loggerServiceProvider.overrideWithValue(mockLoggerService),
    cacheManagerProvider.overrideWithValue(mockCacheManager),
  ],
);
```

##### リアルタイム機能のモック化
```dart
class MockRealtimeManager extends Mock implements RealtimeManager {
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController.broadcast();
      
  Stream<Map<String, dynamic>> get messageStream => 
      _messageController.stream;
      
  void simulateMessage(Map<String, dynamic> message) {
    _messageController.add(message);
  }
}
```

---

## 4. Integration Tests実装計画

### 4.1 テスト環境セットアップ

#### Supabase Test Environment
```dart
// integration_test/setup/supabase_test_setup.dart
class SupabaseTestSetup {
  static late SupabaseClient testClient;
  
  static Future<void> initialize() async {
    testClient = SupabaseClient(
      'https://test-project.supabase.co',
      'test-anon-key',
    );
  }
  
  static Future<void> resetTestData() async {
    // テストデータのクリーンアップとセットアップ
  }
}
```

### 4.2 Repository統合テスト

#### MaterialRepository統合テスト
**ファイル**: `integration_test/repositories/material_repository_integration_test.dart`

```dart
group('MaterialRepository Integration Tests', () {
  // データベース連携
  test('実際のSupabase接続でのCRUD操作');
  test('複雑なクエリでのデータ取得');
  test('トランザクション処理');
  
  // マルチテナント機能
  test('ユーザー別データ分離確認');
  test('不正アクセスの遮断確認');
  
  // パフォーマンス
  test('大量データでの検索性能');
  test('同時更新での整合性確認');
});
```

### 4.3 Services統合テスト

#### 在庫管理フロー統合テスト
**ファイル**: `integration_test/flows/inventory_management_flow_test.dart`

```dart
group('Inventory Management Flow Tests', () {
  test('材料追加→在庫更新→アラート生成フロー');
  test('発注提案→承認→発注実行フロー');
  test('リアルタイム在庫監視フロー');
  
  // エラーケース
  test('ネットワーク断絶時の復旧フロー');
  test('データ不整合発生時の処理フロー');
});
```

### 4.4 マルチテナント統合テスト

```dart
group('Multi-Tenant Integration Tests', () {
  test('複数ユーザー同時アクセス');
  test('ユーザー間データ分離確認');
  test('権限ベースアクセス制御');
  test('セッション管理の確認');
});
```

---

## 5. テスト実装スケジュール（Core層統合版）

### 5.1 Phase 1: 基盤整備（週1-2）

#### Week 1: テスト環境構築
- [ ] testディレクトリ構造作成（Core層拡張版）
- [ ] Core層専用テストユーティリティ作成
- [ ] Core層モッククラス作成（Singleton, Provider対応）
- [ ] Supabase test environment設定

```
test/
├── core/
│   ├── base/
│   ├── cache/                 ★新規追加
│   ├── constants/             ★新規追加
│   ├── infrastructure/        ★新規追加
│   ├── logging/               ★新規追加
│   ├── providers/             ★新規追加
│   ├── realtime/              ★新規追加
│   ├── services/              ★新規追加
│   ├── utils/
│   ├── validation/            ★新規追加
│   └── mocks/
├── features/
│   ├── analytics/
│   ├── auth/
│   ├── inventory/
│   ├── menu/
│   └── order/
├── helpers/
│   ├── test_data_factory.dart
│   ├── mock_providers.dart     ★Core対応拡張
│   ├── singleton_test_helper.dart ★新規追加
│   └── test_utilities.dart
└── integration_test/
    ├── setup/
    ├── repositories/
    ├── core_systems/           ★新規追加
    └── flows/
```

#### Week 2: 基盤・Core P0クラステスト
- [ ] BaseRepository完全テスト実装
- [ ] BaseMultiTenantRepository完全テスト実装
- [ ] YataLoggerService完全テスト実装 ★新規追加
- [ ] CacheManager完全テスト実装 ★新規追加
- [ ] QueryUtilsテスト実装
- [ ] 基盤テストのCI統合

### 5.2 Phase 2: Core層・主要機能テスト（週3-6）

#### Week 3: Priority P0テスト（Features + Core）
- [ ] InventoryService完全テスト実装
- [ ] 主要Repository（Material, Order）テスト実装
- [ ] Core P0クラス統合テスト実装
- [ ] Logging-Cache連携テスト実装 ★新規追加

#### Week 4: Priority P1テスト（Core層重点）
- [ ] CommonProviders完全テスト実装 ★新規追加
- [ ] RealtimeManager完全テスト実装 ★新規追加
- [ ] OrderWorkflowServiceテスト実装
- [ ] AuthServiceテスト実装
- [ ] Core P1統合テスト実装 ★新規追加

#### Week 5: Priority P2テスト＋Core層統合
- [ ] TypeValidator・InputValidatorテスト実装 ★新規追加
- [ ] 残り全Repositoryテスト実装
- [ ] 残り全Servicesテスト実装
- [ ] Core層例外処理テスト実装 ★新規追加

#### Week 6: システム統合テスト（Core重点）
- [ ] Core層間連携テスト（Logger-Cache-Realtime）★新規追加
- [ ] Provider依存関係テスト ★新規追加
- [ ] 包括的統合テスト実装
- [ ] パフォーマンステスト（Core層重点）★新規追加

### 5.3 Phase 3: 品質管理＋最適化（週7-8）

#### Week 7: 品質向上（Core層統合）
- [ ] カバレッジ測定・改善（目標: Core P0層95%, P1層90%, P2層85%）★更新
- [ ] Core層パフォーマンステスト実装 ★新規追加
- [ ] エッジケース・エラーケーステスト追加
- [ ] Singleton・Provider・リアルタイム機能の安定性テスト ★新規追加

#### Week 8: 運用整備（Core層対応）
- [ ] CI/CDパイプライン完全統合（Core層テスト含む）★更新
- [ ] Core層テストドキュメント整備 ★新規追加
- [ ] チーム向けテスト実行ガイド作成（Core層ベストプラクティス含む）★更新
- [ ] Core層テスト保守ガイドライン作成 ★新規追加

---

## 6. 品質指標とCI/CD統合

### 6.1 品質目標

| 指標 | 目標値 | 測定方法 |
|------|--------|----------|
| **Unit Test Coverage** | 90%以上 | flutter test --coverage |
| **Integration Test Coverage** | 主要フロー100% | 手動チェックリスト |
| **Test Execution Time** | 5分以内 | CI/CD pipeline測定 |
| **Flaky Test Rate** | 1%以下 | 10回実行での成功率 |

### 6.2 CI/CDパイプライン統合

#### GitHub Actions設定
**ファイル**: `.github/workflows/backend_tests.yml`

```yaml
name: Backend Tests

on:
  push:
    branches: [ main, dev ]
    paths: 
      - 'lib/features/*/repositories/**'
      - 'lib/features/*/services/**'
      - 'lib/core/**'
  pull_request:
    branches: [ main ]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Run unit tests
      run: flutter test --coverage test/core/ test/features/
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info

  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    
    - name: Setup Supabase Local
      run: |
        npm install -g @supabase/cli
        supabase start
    
    - name: Run integration tests
      run: flutter test integration_test/
```

### 6.3 品質ゲート

#### Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Unit tests実行
flutter test test/core/ test/features/
if [ $? -ne 0 ]; then
  echo "Unit tests failed"
  exit 1
fi

# カバレッジチェック
flutter test --coverage
coverage_percent=$(lcov --summary coverage/lcov.info | grep -o '[0-9.]*%' | tail -1 | sed 's/%//')
if (( $(echo "$coverage_percent < 90" | bc -l) )); then
  echo "Coverage $coverage_percent% is below 90%"
  exit 1
fi
```

---

## 7. 実装ガイドライン

### 7.1 テストファイル命名規約

```
# Unit Tests
test/{module_path}/{class_name}_test.dart

例:
test/core/base/base_repository_test.dart
test/features/inventory/services/inventory_service_test.dart

# Integration Tests  
integration_test/{category}/{test_name}_integration_test.dart

例:
integration_test/repositories/material_repository_integration_test.dart
integration_test/flows/inventory_management_flow_test.dart
```

### 7.2 テストケース構造

```dart
group('{クラス名} Tests', () {
  late {クラス名} target;
  late Mock{依存クラス名} mock{依存クラス名};
  
  setUp(() {
    // テストセットアップ
  });
  
  tearDown(() {
    // クリーンアップ
  });
  
  group('{メソッド名}', () {
    test('正常系 - {説明}', () async {
      // Given
      // When  
      // Then
    });
    
    test('異常系 - {エラー条件}', () async {
      // Given
      // When
      // Then
    });
  });
});
```

### 7.3 テストデータ管理

#### TestDataFactory
```dart
class TestDataFactory {
  static Material createMaterial({
    String? id,
    String? name,
    String? userId,
  }) {
    return Material(
      id: id ?? 'test-material-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Material',
      userId: userId ?? 'test-user-1',
      // ...
    );
  }
  
  static List<Material> createMaterials(int count) {
    return List.generate(count, (index) => createMaterial(
      id: 'test-material-$index',
      name: 'Test Material $index',
    ));
  }
}
```

---

## 8. リスク管理

### 8.1 技術リスク（Core層統合版）

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| **Supabase接続不安定** | 高 | 中 | ローカルSupabase環境、リトライ機構 |
| **Singletonテスト困難** | 高 | 高 | テスト専用インスタンス注入機構 ★新規追加 |
| **Providerモック複雑性** | 中 | 高 | 専用モックヘルパー、テストコンテナ ★新規追加 |
| **リアルタイム機能テスト不安定** | 高 | 中 | WebSocketモック、タイムアウト制御 ★新規追加 |
| **テスト実行時間超過** | 中 | 高 | 並列実行、テスト分割、Core層優先 |
| **モック化困難** | 高 | 中 | インターフェース抽象化リファクタリング |
| **データ競合状態** | 高 | 低 | トランザクション分離、テストデータ分離 |

### 8.2 スケジュールリスク

| リスク | 対策 |
|--------|------|
| **複雑性の過小評価** | バッファ期間確保、優先度ベース実装 |
| **リソース不足** | 段階的実装、自動化優先 |
| **技術的負債発覚** | リファクタリング時間確保 |

---

## 9. 成功指標と完了条件

### 9.1 成功指標（Core層統合版）

#### 定量的指標
- [ ] **Core P0層カバレッジ 95%以上達成** ★新規追加
- [ ] **Core P1層カバレッジ 90%以上達成** ★新規追加  
- [ ] **Core P2層カバレッジ 85%以上達成** ★新規追加
- [ ] Features層 Unit Testカバレッジ 90%以上達成
- [ ] Integration Test 主要フロー100%達成
- [ ] **Core層統合テスト 100%達成** ★新規追加
- [ ] CI/CDパイプライン実行時間 7分以内（Core層追加考慮）★更新
- [ ] テスト実行成功率 99%以上

#### 定性的指標
- [ ] 全開発者がテストを理解・実行可能
- [ ] リファクタリング時の安全性確保
- [ ] バグ検出の早期化実現
- [ ] コードレビュー効率向上

### 9.2 完了条件

#### Phase 1完了条件
- [ ] テスト環境が完全構築されている
- [ ] 基盤クラステストが完了している
- [ ] CI/CDパイプラインが動作している

#### Phase 2完了条件
- [ ] 全Priority P0-P1クラスのテストが完了している
- [ ] 基本的な統合テストが実装されている
- [ ] カバレッジ目標を80%以上達成している

#### Phase 3完了条件
- [ ] 全バックエンドクラスのテストが完了している
- [ ] 品質指標を全て満たしている
- [ ] 運用ドキュメントが整備されている
- [ ] チームメンバーの理解が完了している

---

## 10. 継続的改善計画

### 10.1 定期的レビュー

#### 週次レビュー
- テスト実行結果確認
- カバレッジレポート分析
- フレーキーテスト特定・修正

#### 月次レビュー
- テスト戦略有効性評価
- パフォーマンス傾向分析
- 新規機能のテスト計画策定

#### 四半期レビュー
- テストアーキテクチャ見直し
- ツール・フレームワーク評価
- 長期的改善計画策定

### 10.2 継続的改善項目

1. **テスト自動化拡張**: E2Eテスト、パフォーマンステスト
2. **テストデータ管理**: より現実的なテストデータ生成
3. **可視化改善**: テスト結果ダッシュボード
4. **教育・トレーニング**: 新メンバー向けテスト教育

---

## 11. 結論（Core層統合版）

### 11.1 計画の意義

本テスト実装計画は、**Repository/Services層に加えてCore層（89ファイル）を包含**した、YATAプロジェクトの完全なバックエンド層テストカバレッジを目指している。特にシステムの基盤となるLogging、Cache、Realtime、Providersシステムの安定性確保により、**長期的な品質向上と開発効率化**を実現する。

### 11.2 期待効果（Core層統合）

1. **品質向上**: バグの早期発見・修正、**特にCore層の隠れたバグの撲滅**
2. **開発効率**: 安全なリファクタリング、コードレビュー効率化、**Core層の変更への迅速対応**
3. **保守性**: 長期的なコード品質維持、**システム全体の基盤安定性確保**
4. **チーム成長**: テスト駆動開発文化の醸成、**Core層アーキテクチャの深い理解**
5. **システム堅牢性**: **Singleton、Provider、リアルタイム機能の安定運用** ★新規効果

### 11.3 実装スコープ（最終確定）

#### 対象範囲
- **Core層**: 89ファイル、9モジュール（Logging, Cache, Providers等）
- **Repository層**: 32クラス、8フィーチャー
- **Services層**: 22クラス、8フィーチャー
- **総計**: **143クラス、包括的バックエンド層カバレッジ**

#### 実装期間・工数
- **期間**: 8週間（Core層統合により1週間延長）
- **Phase構成**: 3フェーズ、段階的実装
- **優先度**: P0(Core基盤) → P1(高機能) → P2(完全性)

### 11.4 推奨アクション

1. **即座開始**: Phase 1のCore層対応環境構築から着手
2. **段階的実装**: Core P0優先の計画的実装
3. **継続的改善**: Core層レビューサイクルの確立
4. **チーム共有**: 実装進捗と知見の共有、**Core層ベストプラクティス共有**

### 11.5 最終的価値

この**Core層統合包括的テスト実装**により、YATAプロジェクトは：
- **システム基盤の盤石な安定性**
- **長期運用での信頼性確保**
- **開発チームの技術力向上**
- **保守・拡張時の安全性担保**

を実現し、**真に堅牢で持続可能なシステム**へと進化することが期待される。

---
