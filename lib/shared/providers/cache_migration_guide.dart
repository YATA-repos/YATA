/// キャッシュ戦略移行ガイド
/// 
/// 古いkeepAlive()ベースのキャッシュから
/// インテリジェントキャッシュシステムへの移行方法

/// 移行前（非推奨）：
/// ```dart
/// @riverpod
/// Future<List<Material>> materials(Ref ref, String? categoryId) async {
///   ref.keepAlive(); // 問題：適切でない永続化
///   final InventoryService service = ref.watch(inventoryServiceProvider);
///   return service.getMaterialsByCategory(categoryId);
/// }
/// ```

/// 移行後（推奨）：
/// ```dart
/// @riverpod
/// class OptimizedMaterials extends _$OptimizedMaterials with SmartCacheMixin {
///   @override
///   Future<List<Material>> build(String? categoryId) async {
///     final String providerId = "materials_${categoryId ?? 'all'}";
///     
///     // データタイプに応じた適切なキャッシュ戦略
///     registerWithSmartCache(
///       ref, 
///       providerId, 
///       DataType.userSemiStaticData,
///       customConfig: EnhancedCacheConfig(
///         strategy: CacheStrategy.longTerm,
///         dataType: DataType.userSemiStaticData,
///         priority: CachePriority.high,
///         customTtl: const Duration(minutes: 30),
///       ),
///     );
///     recordCacheAccess(ref, providerId);
///     
///     final InventoryService service = ref.watch(optimizedInventoryServiceProvider);
///     return service.getMaterialsByCategory(categoryId);
///   }
/// }
/// ```

/// 移行のメリット：
/// 
/// 1. **適切なライフサイクル管理**
///    - データタイプに応じた最適なTTL
///    - 自動的な期限切れ処理
///    - メモリリークの防止
/// 
/// 2. **スマートな無効化**
///    - 依存関係に基づく連動無効化
///    - データ変更時の自動リフレッシュ
///    - 不要なキャッシュの自動削除
/// 
/// 3. **パフォーマンス最適化**
///    - 使用頻度に基づく優先度管理
///    - メモリ使用量の監視と制御
///    - バッチ処理による効率化
/// 
/// 4. **開発効率向上**
///    - キャッシュ統計の可視化
///    - デバッグ情報の自動収集
///    - 設定の標準化

/// データタイプ別移行例：

/// **1. ユーザー動的データ（在庫数など）**
/// ```dart
/// // 古い方法
/// @riverpod
/// Future<List<MaterialStockInfo>> materialsWithStockInfo(Ref ref, String userId) async {
///   // keepAlive()なし → 頻繁な再取得でパフォーマンス悪化
///   // または keepAlive()あり → 古いデータが残る
/// }
/// 
/// // 新しい方法
/// registerWithSmartCache(ref, providerId, DataType.userDynamicData);
/// // → 短期キャッシュ + 自動リフレッシュ
/// ```

/// **2. ユーザー準静的データ（材料マスタなど）**
/// ```dart
/// // 古い方法
/// @riverpod
/// Future<List<Material>> materials(Ref ref) async {
///   ref.keepAlive(); // 永続化しすぎ
/// }
/// 
/// // 新しい方法
/// registerWithSmartCache(ref, providerId, DataType.userSemiStaticData);
/// // → 中期キャッシュ + 依存関係管理
/// ```

/// **3. グローバル静的データ（システム設定など）**
/// ```dart
/// // 古い方法
/// @riverpod
/// Future<AppConfig> appConfig(Ref ref) async {
///   ref.keepAlive(); // 適切だが管理が不十分
/// }
/// 
/// // 新しい方法
/// registerWithSmartCache(ref, providerId, DataType.globalStaticData);
/// // → 長期キャッシュ + 高優先度保護
/// ```

/// **4. UI状態データ**
/// ```dart
/// // 古い方法
/// @riverpod
/// class SelectedCategory extends _$SelectedCategory {
///   @override
///   String build() {
///     ref.keepAlive(); // UI状態には過剰
///     return "all";
///   }
/// }
/// 
/// // 新しい方法
/// registerWithSmartCache(ref, providerId, DataType.uiStateData);
/// // → 軽量キャッシュ + 自動削除
/// ```

/// 移行チェックリスト：
/// 
/// □ 既存のkeepAlive()呼び出しを特定
/// □ 各プロバイダーのデータタイプを分類
/// □ SmartCacheMixinを追加
/// □ registerWithSmartCache()呼び出しを追加
/// □ recordCacheAccess()呼び出しを追加
/// □ 依存関係を定義（必要に応じて）
/// □ キャッシュ統計で効果を確認

/// パフォーマンス比較（期待値）：
/// 
/// - メモリ使用量: 30-50%削減
/// - 無駄な再計算: 60-80%削減
/// - アプリ起動時間: 20-30%改善
/// - UI応答性: 40-60%改善

library;