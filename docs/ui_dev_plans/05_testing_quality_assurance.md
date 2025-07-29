# Phase 5: テスト・品質管理計画

## 概要

Phase 1-4で実装したUI層の品質を確保するため、包括的なテスト戦略と品質管理プロセスを実装する。Flutterのテストエコシステムを活用し、継続的な品質向上を図る。

## 1. テスト戦略

### 1.1 テストピラミッド

```
                🔺
               /  \
              / E2E \     (少数・高価値)
             /------\
            / Widget \    (中核・バランス)
           /----------\
          / Unit Tests \  (多数・高速)
         /--------------\
```

### 1.2 テスト分類と責任範囲

#### Unit Tests (単体テスト)
- **対象**: データモデル、プロバイダー、ユーティリティ
- **目的**: 個別機能の正確性検証
- **実行頻度**: 毎回のビルド時

#### Widget Tests (Widgetテスト)
- **対象**: 個別Widget、画面コンポーネント
- **目的**: UI動作とユーザーインタラクション検証
- **実行頻度**: CI/CD パイプライン

#### Integration Tests (統合テスト)
- **対象**: 画面遷移、サービス統合、データフロー
- **目的**: 機能間連携とエンドツーエンド動作検証
- **実行頻度**: リリース前

## 2. 単体テスト実装

### 2.1 データモデルテスト

#### UI モデルテスト例
```dart
// test/shared/models/ui_menu_item_test.dart
void main() {
  group('UiMenuItem', () {
    test('should create instance with required fields', () {
      const menuItem = UiMenuItem(
        id: '1',
        name: 'Test Item',
        price: 100.0,
        category: 'main',
      );

      expect(menuItem.id, '1');
      expect(menuItem.name, 'Test Item');
      expect(menuItem.price, 100.0);
      expect(menuItem.category, 'main');
      expect(menuItem.isAvailable, true);
      expect(menuItem.stockCount, 0);
    });

    test('should convert from domain model correctly', () {
      final domainModel = MenuItemModel(
        id: '1',
        name: 'Domain Item',
        price: Decimal.fromInt(200),
        category: 'main',
        isAvailable: false,
        stockCount: 5,
      );

      final uiModel = UiMenuItem.fromDomain(domainModel);

      expect(uiModel.id, '1');
      expect(uiModel.name, 'Domain Item');
      expect(uiModel.price, 200.0);
      expect(uiModel.isAvailable, false);
      expect(uiModel.stockCount, 5);
    });

    group('Json serialization', () {
      test('should serialize to json correctly', () {
        const menuItem = UiMenuItem(
          id: '1',
          name: 'Test Item',
          price: 100.0,
          category: 'main',
        );

        final json = menuItem.toJson();

        expect(json['id'], '1');
        expect(json['name'], 'Test Item');
        expect(json['price'], 100.0);
        expect(json['category'], 'main');
      });

      test('should deserialize from json correctly', () {
        final json = {
          'id': '1',
          'name': 'Test Item',
          'price': 100.0,
          'category': 'main',
          'isAvailable': true,
          'stockCount': 0,
        };

        final menuItem = UiMenuItem.fromJson(json);

        expect(menuItem.id, '1');
        expect(menuItem.name, 'Test Item');
        expect(menuItem.price, 100.0);
        expect(menuItem.category, 'main');
      });
    });
  });
}
```

### 2.2 プロバイダーテスト

#### Riverpod プロバイダーテスト例
```dart
// test/features/order/presentation/providers/order_providers_test.dart
void main() {
  group('CurrentOrder Provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with empty list', () {
      final currentOrder = container.read(currentOrderProvider);
      
      expect(currentOrder, isEmpty);
    });

    test('should add new item to order', () {
      const menuItem = UiMenuItem(
        id: '1',
        name: 'Test Item',
        price: 100.0,
        category: 'main',
      );

      container.read(currentOrderProvider.notifier).addItem(menuItem);
      final currentOrder = container.read(currentOrderProvider);

      expect(currentOrder, hasLength(1));
      expect(currentOrder.first.menuItemId, '1');
      expect(currentOrder.first.quantity, 1);
    });

    test('should increase quantity when adding existing item', () {
      const menuItem = UiMenuItem(
        id: '1',
        name: 'Test Item',
        price: 100.0,
        category: 'main',
      );

      final notifier = container.read(currentOrderProvider.notifier);
      notifier.addItem(menuItem);
      notifier.addItem(menuItem);

      final currentOrder = container.read(currentOrderProvider);

      expect(currentOrder, hasLength(1));
      expect(currentOrder.first.quantity, 2);
    });

    test('should remove item from order', () {
      const menuItem = UiMenuItem(
        id: '1',
        name: 'Test Item',
        price: 100.0,
        category: 'main',
      );

      final notifier = container.read(currentOrderProvider.notifier);
      notifier.addItem(menuItem);
      notifier.removeItem('1');

      final currentOrder = container.read(currentOrderProvider);

      expect(currentOrder, isEmpty);
    });

    test('should calculate order summary correctly', () {
      const menuItem1 = UiMenuItem(
        id: '1',
        name: 'Item 1',
        price: 100.0,
        category: 'main',
      );
      const menuItem2 = UiMenuItem(
        id: '2',
        name: 'Item 2',
        price: 200.0,
        category: 'main',
      );

      final notifier = container.read(currentOrderProvider.notifier);
      notifier.addItem(menuItem1);
      notifier.addItem(menuItem2);
      notifier.addItem(menuItem2); // quantity: 2

      final summary = container.read(orderSummaryProvider);

      expect(summary.subtotal, 500.0); // 100 + 200*2
      expect(summary.tax, 50.0); // 10%
      expect(summary.total, 550.0);
      expect(summary.itemCount, 3);
    });
  });
}
```

## 3. Widgetテスト実装

### 3.1 共通Widgetテスト

#### AppButton テスト例
```dart
// test/shared/widgets/buttons/app_button_test.dart
void main() {
  group('AppButton Widget Tests', () {
    testWidgets('should display text correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('should handle tap events', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Test Button',
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Button'));
      await tester.pumpAndSettle();

      expect(wasPressed, true);
    });

    testWidgets('should show loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Test Button',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should be disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Test Button',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    group('Button variants', () {
      testWidgets('should apply primary variant styles', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                text: 'Primary Button',
                variant: ButtonVariant.primary,
                onPressed: () {},
              ),
            ),
          ),
        );

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final style = button.style;
        
        // スタイル検証ロジック
        expect(style, isNotNull);
      });
    });
  });
}
```

#### StatsCard テスト例
```dart
// test/shared/widgets/cards/stats_card_test.dart
void main() {
  group('StatsCard Widget Tests', () {
    testWidgets('should display title and value correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Total Sales',
              value: '¥12,345',
            ),
          ),
        ),
      );

      expect(find.text('Total Sales'), findsOneWidget);
      expect(find.text('¥12,345'), findsOneWidget);
    });

    testWidgets('should display subtitle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Total Sales',
              value: '¥12,345',
              subtitle: '+5.2% from yesterday',
            ),
          ),
        ),
      );

      expect(find.text('+5.2% from yesterday'), findsOneWidget);
    });

    testWidgets('should handle tap events', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: 'Total Sales',
              value: '¥12,345',
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatsCard));
      await tester.pumpAndSettle();

      expect(wasTapped, true);
    });
  });
}
```

### 3.2 画面コンポーネントテスト

#### Dashboard Screen テスト例
```dart
// test/features/dashboard/presentation/screens/dashboard_screen_test.dart
void main() {
  group('DashboardScreen Widget Tests', () {
    late MockMenuService mockMenuService;
    late MockOrderService mockOrderService;

    setUp(() {
      mockMenuService = MockMenuService();
      mockOrderService = MockOrderService();
    });

    testWidgets('should display mode selector', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            menuServiceProvider.overrideWithValue(mockMenuService),
            orderServiceProvider.overrideWithValue(mockOrderService),
          ],
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      expect(find.byType(ModeSelector), findsOneWidget);
      expect(find.text('オーダー作成'), findsOneWidget);
      expect(find.text('在庫状況'), findsOneWidget);
    });

    testWidgets('should switch between order and inventory modes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            menuServiceProvider.overrideWithValue(mockMenuService),
            orderServiceProvider.overrideWithValue(mockOrderService),
          ],
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      // 初期状態はオーダーモード
      expect(find.byType(OrderModeView), findsOneWidget);
      expect(find.byType(InventoryModeView), findsNothing);

      // 在庫モードに切り替え
      await tester.tap(find.text('在庫状況'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderModeView), findsNothing);
      expect(find.byType(InventoryModeView), findsOneWidget);
    });

    testWidgets('should show mobile navigation on mobile devices', (tester) async {
      // モバイルサイズに設定
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            menuServiceProvider.overrideWithValue(mockMenuService),
            orderServiceProvider.overrideWithValue(mockOrderService),
          ],
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      expect(find.byType(MobileBottomNavigation), findsOneWidget);

      // 元のサイズに戻す
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });
  });
}
```

## 4. 統合テスト実装

### 4.1 統合テストセットアップ

```dart
// integration_test/app_test.dart
void main() {
  group('App Integration Tests', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    testWidgets('complete order flow test', (tester) async {
      await tester.pumpWidget(MyApp());

      // ダッシュボード画面の表示確認
      expect(find.byType(DashboardScreen), findsOneWidget);

      // メニューアイテムの選択
      await tester.tap(find.text('チキンカレー').first);
      await tester.pumpAndSettle();

      // カートに追加されることを確認
      expect(find.text('1'), findsOneWidget); // 数量表示

      // 注文確定ボタンをタップ
      await tester.tap(find.text('注文確定'));
      await tester.pumpAndSettle();

      // 注文状況画面への遷移確認
      expect(find.byType(OrderStatusScreen), findsOneWidget);
    });

    testWidgets('inventory management flow test', (tester) async {
      await tester.pumpWidget(MyApp());

      // 在庫モードに切り替え
      await tester.tap(find.text('在庫状況'));
      await tester.pumpAndSettle();

      // 在庫一覧の表示確認
      expect(find.byType(InventoryModeView), findsOneWidget);

      // 検索機能のテスト
      await tester.enterText(find.byType(SearchField), 'チキン');
      await tester.pumpAndSettle();

      // フィルター結果の確認
      expect(find.text('チキンカレー'), findsOneWidget);
    });
  });
}
```

### 4.2 パフォーマンステスト

```dart
// test/performance/performance_test.dart
void main() {
  group('Performance Tests', () {
    testWidgets('menu items list should render smoothly', (tester) async {
      // 大量のメニューアイテムを生成
      final menuItems = List.generate(1000, (index) => UiMenuItem(
        id: '$index',
        name: 'Menu Item $index',
        price: 100.0 + index,
        category: 'category${index % 5}',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) => MenuItemCard(
                name: menuItems[index].name,
                price: menuItems[index].price,
                onAdd: () {},
              ),
            ),
          ),
        ),
      );

      // スクロールパフォーマンステスト
      await tester.fling(find.byType(ListView), const Offset(0, -500), 1000);
      await tester.pumpAndSettle();

      // メモリリークテスト
      expect(tester.allWidgets.length, lessThan(2000));
    });
  });
}
```

## 5. 品質メトリクス

### 5.1 カバレッジ目標

- **Unit Tests**: 90%以上
- **Widget Tests**: 80%以上
- **Integration Tests**: 主要フロー100%

### 5.2 カバレッジ計測

```bash
# カバレッジレポート生成
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 5.3 CI/CDパイプライン統合

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test --coverage
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
```

## 6. コード品質管理

### 6.1 静的解析

```yaml
# analysis_options.yaml (拡張)
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    # UI専用ルール
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - sized_box_for_whitespace
    - use_key_in_widget_constructors
```

### 6.2 コードレビューチェックリスト

#### Widget実装チェック
- [ ] 適切なkey設定
- [ ] const constructorの使用
- [ ] BuildContextの適切な使用
- [ ] 状態管理の適切性
- [ ] レスポンシブ対応

#### プロバイダー実装チェック
- [ ] 依存関係の適切性
- [ ] メモリリーク防止
- [ ] エラーハンドリング
- [ ] テスタビリティ

## 7. 実装スケジュール

### Week 1: テスト環境構築
- [ ] テストユーティリティ作成
- [ ] モックサービス作成
- [ ] CI/CD パイプライン設定

### Week 2: 単体テスト実装
- [ ] データモデルテスト
- [ ] プロバイダーテスト
- [ ] ユーティリティテスト

### Week 3: Widgetテスト実装
- [ ] 共通Widgetテスト
- [ ] 画面コンポーネントテスト
- [ ] インタラクションテスト

### Week 4: 統合テスト・品質管理
- [ ] 統合テスト実装
- [ ] パフォーマンステスト
- [ ] カバレッジ改善
- [ ] ドキュメント整備

## 8. 完了条件

- [ ] 目標カバレッジを達成している
- [ ] 全テストがCIで自動実行される
- [ ] パフォーマンステストが通過する
- [ ] コード品質メトリクスが基準を満たす
- [ ] テストドキュメントが整備されている

## 9. 継続的改善

### 9.1 定期的なメトリクス確認
- 毎週のカバレッジレポート確認
- 月次のパフォーマンス評価
- 四半期ごとのテスト戦略見直し

### 9.2 テスト追加の判断基準
- バグ発生時の再発防止テスト
- 新機能追加時の回帰テスト
- ユーザーフィードバックに基づく改善テスト

この包括的なテスト戦略により、高品質なUI実装を継続的に維持し、安定したアプリケーションの提供を実現する。