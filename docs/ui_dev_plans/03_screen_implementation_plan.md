# Phase 3: 画面別実装計画

## 概要

Phase 2で実装した共通Widgetライブラリを活用し、5つの主要画面を段階的に実装する。既存のサービスレイヤーとの統合も考慮した実装順序で進める。

## 実装優先順位と依存関係

### 1. ダッシュボード画面（最優先）
- **理由**: アプリケーションの中核機能
- **依存**: AppButton, AppCard, ModeSelector, MenuItemCard, StatsCard
- **サービス統合**: order, menu, inventory サービス

### 2. 注文状況画面（高優先）
- **理由**: ダッシュボードと密接に関連
- **依存**: AppCard, AppBadge, LoadingIndicator
- **サービス統合**: order, kitchen サービス

### 3. 在庫管理画面（中優先）
- **理由**: 独立性が高い
- **依存**: StatsCard, AppTextField, SearchField
- **サービス統合**: inventory, stock サービス

### 4. 注文履歴画面（中優先）
- **理由**: 分析機能との連携
- **依存**: SearchField, CategoryFilter, AppBadge
- **サービス統合**: order サービス

### 5. 売上分析画面（低優先）
- **理由**: チャート依存、複雑度高
- **依存**: StatsCard + チャートライブラリ
- **サービス統合**: analytics サービス

## 1. ダッシュボード画面 (`features/dashboard/`)

### 1.1 実装構造

```
features/dashboard/
├── presentation/
│   ├── providers/
│   │   ├── dashboard_provider.dart
│   │   └── order_mode_provider.dart
│   ├── screens/
│   │   └── dashboard_screen.dart
│   └── widgets/
│       ├── dashboard_app_bar.dart
│       ├── order_mode_view.dart
│       ├── inventory_mode_view.dart
│       ├── menu_selection_panel.dart
│       ├── menu_panel_header.dart
│       ├── menu_item_grid.dart
│       ├── current_order_panel.dart
│       ├── order_panel_header.dart
│       ├── order_items_list.dart
│       ├── order_summary.dart
│       └── order_actions.dart
```

### 1.2 主要コンポーネント実装

#### DashboardScreen
```dart
class DashboardScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String selectedMode = 'order';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(),
      body: Column(
        children: [
          ModeSelector(
            selectedMode: selectedMode,
            onModeChanged: (mode) => setState(() => selectedMode = mode),
            options: [
              ModeOption(
                id: 'order', 
                label: 'オーダー作成', 
                icon: Icons.shopping_cart,
                badgeCount: ref.watch(pendingOrdersCountProvider),
              ),
              ModeOption(
                id: 'inventory', 
                label: '在庫状況', 
                icon: Icons.layers,
                badgeCount: ref.watch(lowStockCountProvider),
              ),
            ],
          ),
          Expanded(
            child: selectedMode == 'order' 
                ? const OrderModeView() 
                : const InventoryModeView(),
          ),
        ],
      ),
      bottomNavigationBar: ResponsiveHelper.isMobile(context) 
          ? const MobileBottomNavigation() 
          : null,
    );
  }
}
```

#### 実装タスク
- [ ] DashboardScreen基本実装
- [ ] OrderModeView実装
- [ ] InventoryModeView実装
- [ ] MenuSelectionPanel実装
- [ ] CurrentOrderPanel実装
- [ ] レスポンシブレイアウト対応
- [ ] 既存サービスとの統合
- [ ] 状態管理（Riverpod Provider）
- [ ] Widget テスト作成

### 1.3 依存サービス
- MenuService: メニューアイテム取得
- OrderService: 注文管理
- CartService: カート操作
- InventoryService: 在庫状況確認

## 2. 注文状況画面 (`features/order_status/`)

### 2.1 実装構造

```
features/order_status/
├── presentation/
│   ├── providers/
│   │   └── order_status_provider.dart
│   ├── screens/
│   │   └── order_status_screen.dart
│   └── widgets/
│       ├── active_orders_grid.dart
│       ├── order_status_card.dart
│       ├── order_card_header.dart
│       ├── order_items_list.dart
│       ├── order_progress.dart
│       └── order_card_actions.dart
```

### 2.2 主要コンポーネント実装

#### OrderStatusScreen
```dart
class OrderStatusScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrders = ref.watch(activeOrdersProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('注文状況')),
      body: activeOrders.when(
        data: (orders) => orders.isEmpty
            ? const EmptyState(
                title: '進行中の注文がありません',
                subtitle: '新しい注文を作成してください',
                icon: Icons.receipt_long,
              )
            : ActiveOrdersGrid(orders: orders),
        loading: () => const LoadingIndicator(
          message: '注文状況を読み込み中...',
        ),
        error: (error, stack) => ErrorWidget(error),
      ),
    );
  }
}
```

#### 実装タスク
- [ ] OrderStatusScreen基本実装
- [ ] ActiveOrdersGrid実装
- [ ] OrderStatusCard実装
- [ ] リアルタイム更新対応
- [ ] 注文ステータス更新機能
- [ ] 既存KitchenServiceとの統合
- [ ] Widget テスト作成

### 2.3 依存サービス
- OrderService: 注文取得・更新
- KitchenService: 調理状況管理

## 3. 在庫管理画面 (`features/inventory/`)

### 3.1 実装構造

```
features/inventory/
├── presentation/
│   ├── providers/
│   │   └── inventory_provider.dart
│   ├── screens/
│   │   └── inventory_screen.dart
│   └── widgets/
│       ├── inventory_stats_row.dart
│       ├── inventory_filters.dart
│       ├── inventory_table.dart
│       ├── inventory_table_header.dart
│       ├── inventory_table_row.dart
│       └── table_pagination.dart
```

### 3.2 主要コンポーネント実装

#### InventoryScreen
```dart
class InventoryScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String searchQuery = '';
  String selectedCategory = 'all';
  
  @override
  Widget build(BuildContext context) {
    final inventoryStats = ref.watch(inventoryStatsProvider);
    final inventoryItems = ref.watch(filteredInventoryItemsProvider(
      InventoryFilter(
        searchQuery: searchQuery,
        category: selectedCategory,
      ),
    ));
    
    return Scaffold(
      appBar: AppBar(title: const Text('在庫管理')),
      body: Column(
        children: [
          InventoryStatsRow(stats: inventoryStats),
          InventoryFilters(
            onSearchChanged: (query) => setState(() => searchQuery = query),
            onCategoryChanged: (category) => setState(() => selectedCategory = category),
          ),
          Expanded(
            child: InventoryTable(items: inventoryItems),
          ),
        ],
      ),
    );
  }
}
```

#### 実装タスク
- [ ] InventoryScreen基本実装
- [ ] InventoryStatsRow実装
- [ ] InventoryTable実装
- [ ] フィルタリング・検索機能
- [ ] ページネーション実装
- [ ] 在庫アラート表示
- [ ] 既存InventoryServiceとの統合
- [ ] Widget テスト作成

### 3.3 依存サービス
- InventoryService: 在庫データ管理
- MaterialManagementService: 材料管理
- StockLevelService: 在庫レベル管理

## 4. 注文履歴画面 (`features/orders/`)

### 4.1 実装構造

```
features/orders/
├── presentation/
│   ├── providers/
│   │   └── orders_provider.dart
│   ├── screens/
│   │   └── orders_screen.dart
│   └── widgets/
│       ├── order_filters.dart
│       ├── orders_table.dart
│       ├── orders_table_header.dart
│       ├── order_table_row.dart
│       └── table_pagination.dart
```

### 4.2 主要コンポーネント実装

#### OrdersScreen
```dart
class OrdersScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  DateRange? selectedDateRange;
  OrderStatus? selectedStatus;
  
  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(filteredOrdersProvider(
      OrderFilter(
        dateRange: selectedDateRange,
        status: selectedStatus,
      ),
    ));
    
    return Scaffold(
      appBar: AppBar(title: const Text('注文履歴')),
      body: Column(
        children: [
          OrderFilters(
            onDateRangeChanged: (range) => setState(() => selectedDateRange = range),
            onStatusChanged: (status) => setState(() => selectedStatus = status),
          ),
          Expanded(
            child: OrdersTable(orders: orders),
          ),
        ],
      ),
    );
  }
}
```

#### 実装タスク
- [ ] OrdersScreen基本実装
- [ ] OrderFilters実装
- [ ] OrdersTable実装
- [ ] 日付範囲フィルター
- [ ] ステータスフィルター
- [ ] 注文詳細表示
- [ ] エクスポート機能（オプション）
- [ ] Widget テスト作成

### 4.3 依存サービス
- OrderService: 注文履歴取得
- OrderManagementService: 注文管理

## 5. 売上分析画面 (`features/sales/`)

### 5.1 実装構造

```
features/sales/
├── presentation/
│   ├── providers/
│   │   └── sales_provider.dart
│   ├── screens/
│   │   └── sales_screen.dart
│   └── widgets/
│       ├── sales_stats_row.dart
│       ├── sales_period_selector.dart
│       ├── sales_charts.dart
│       ├── daily_sales_chart.dart
│       ├── product_sales_chart.dart
│       └── hourly_analysis_chart.dart
```

### 5.2 主要コンポーネント実装

#### SalesScreen
```dart
class SalesScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  SalesPeriod selectedPeriod = SalesPeriod.today;
  
  @override
  Widget build(BuildContext context) {
    final salesData = ref.watch(salesDataProvider(selectedPeriod));
    
    return Scaffold(
      appBar: AppBar(title: const Text('売上分析')),
      body: Column(
        children: [
          SalesPeriodSelector(
            selectedPeriod: selectedPeriod,
            onPeriodChanged: (period) => setState(() => selectedPeriod = period),
          ),
          salesData.when(
            data: (data) => Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SalesStatsRow(stats: data.stats),
                    SalesCharts(data: data),
                  ],
                ),
              ),
            ),
            loading: () => const Expanded(
              child: LoadingIndicator(message: '売上データを分析中...'),
            ),
            error: (error, stack) => Expanded(
              child: EmptyState(
                title: 'データの読み込みに失敗しました',
                subtitle: error.toString(),
                icon: Icons.error_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 実装タスク
- [ ] SalesScreen基本実装
- [ ] チャートライブラリ選定・統合（fl_chart推奨）
- [ ] DailySalesChart実装
- [ ] ProductSalesChart実装
- [ ] HourlyAnalysisChart実装
- [ ] 期間選択機能
- [ ] 既存AnalyticsServiceとの統合
- [ ] Widget テスト作成

### 5.3 依存サービス
- AnalyticsService: 分析データ取得
- OrderService: 売上データソース

### 5.4 追加依存関係
```yaml
dependencies:
  fl_chart: ^0.65.0  # チャート表示用
```

## 実装スケジュール

### Week 1-2: ダッシュボード画面
- 最重要画面の完全実装
- オーダー作成・在庫表示モード
- レスポンシブ対応

### Week 3: 注文状況画面
- リアルタイム注文状況表示
- ステータス更新機能

### Week 4: 在庫管理画面
- 在庫一覧・統計表示
- フィルター・検索機能

### Week 5: 注文履歴画面
- 履歴表示・フィルター機能
- 詳細表示

### Week 6: 売上分析画面
- チャート表示機能
- 期間別分析

## 完了条件

- [ ] 全5画面が実装されている
- [ ] レスポンシブ対応が完了している
- [ ] 既存サービスレイヤーとの統合が完了している
- [ ] 状態管理（Riverpod）が適切に実装されている
- [ ] Widget テストが作成されている
- [ ] ナビゲーション連携が動作している

## 次のPhaseとの連携

Phase 4（データモデル・状態管理）、Phase 5（テスト・品質管理）では、ここで実装した画面の品質向上と安定性確保を行う。特に重要な連携点：

- 状態管理の最適化
- エラーハンドリングの統一
- パフォーマンス最適化
- 統合テストの実装