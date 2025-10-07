# `lib/features/order/` アーキテクチャ分析レポート

## 1. 総括評価 (Executive Summary)

`lib/features/order/` 配下のソースコードは、フィーチャースライス（Feature-Sliced Design）に基づいた、規律あるアーキテクチャで構築されています。レイヤー間の依存関係は一方向に保たれており（UI → Service → Repository）、全体として堅牢な設計です。

しかし、詳細な分析の結果、いくつかの領域で**凝集度の低下**と**関心事の不必要な分散**が見受けられました。これにより、特定の機能を理解・修正する際に複数のファイルを横断する必要が生じ、保守性や可読性をやや損なっています。

本レポートでは、これらの問題点を具体的に指摘し、コードベースの健全性をさらに向上させるためのリファクタリング案を提案します。

## 2. 問題点の分析と改善提案

### 2.1. モデルの配置場所の不整合

-   **問題点**:
    カートの状態を表現するモデル的クラス `CartSnapshotData` と `CartMutationResult` が、`lib/features/order/services/models/cart_snapshot.dart` に配置されています。一方で、`Order`や`OrderItem`といった主要なドメインエンティティは `lib/features/order/models/order_model.dart` に定義されており、モデルの置き場所に一貫性がありません。

-   **根拠**:
    `order_model.dart` の存在が、`lib/features/order/models/` がこのフィーチャーにおけるモデルクラスの**唯一の標準的な置き場所**であることを示しています。`CartSnapshotData` は、振る舞いを持たないデータコンテナであり、その責務は明らかにモデルです。

-   **改善提案**:
    `lib/features/order/services/models/cart_snapshot.dart` を `lib/features/order/models/cart_snapshot.dart` に移動します。これにより、アーキテクチャのルールが統一され、開発者はモデルを探す際に単一のディレクトリのみを考慮すればよくなります。

### 2.2. サービス層の過度な細分化

-   **問題点**:
    単一のドメイン（例：カート管理）に関するビジネスロジックが、複数のサービスクラスに分散しています。
    -   **カート**: `cart_service.dart` (Facade), `cart_management_service.dart` (Core Logic)
    -   **注文**: `order_service.dart` (Facade), `order_management_service.dart` (Core Logic), `order_calculation_service.dart` (Helper), `order_stock_service.dart` (Helper)

    この構造により、「カートに商品を追加する」という一つのユースケースを追うために、複数のファイルを読み解く必要があります。例えば、`CartManagementService` は金額計算のために `OrderCalculationService` を呼び出しており、不必要なクラス間依存を生んでいます。

-   **根拠 (コード例)**:
    `cart_service.dart` は、実質的なロジックを持たないラッパーです。
    ```dart
    // lib/features/order/services/cart_service.dart
    class CartService {
      // ...
      final CartManagementService _cartManagementService;
      final OrderCalculationService _orderCalculationService;

      Future<CartMutationResult> addItemToCart(...) async =>
          _cartManagementService.addItemToCart(...);

      Future<OrderCalculationResult> calculateCartTotal(...) async =>
          _orderCalculationService.calculateCartTotal(...);
    }
    ```
    これは、`CartManagementService` と `OrderCalculationService` のロジックが本来密接に関連していることを示唆しています。

-   **改善提案**:
    関連性の高いサービスを、ドメインごとに一つのサービスクラスに統合します。
    -   `cart_management_service.dart` のロジックを `cart_service.dart` に統合し、`cart_management_service.dart` を削除します。
    -   同様に、`order_management_service.dart`, `order_calculation_service.dart`, `order_stock_service.dart` の内容を `order_service.dart` に統合します。計算や在庫操作のロジックは、`OrderService` のプライベートメソッドとして実装することで、外部への不要な公開を防ぎます。

### 2.3. プレゼンテーション層ユーティリティの不適切な配置

-   **問題点**:
    UIの表示方法（ステータスの表示名や順序など）を定義するユーティリティ `order_status_presentation.dart` と `order_status_mapper.dart` が、汎用的な `lib/features/order/shared/` ディレクトリに配置されています。

-   **根拠 (コード例)**:
    これらのユーティリティは、UIコンポーネント（Page, Controller）から直接利用されています。
    ```dart
    // lib/features/order/presentation/controllers/order_status_controller.dart
    import "../../shared/order_status_presentation.dart";
    // ...
    final Map<OrderStatus, List<Order>> grouped = await _orderService.getOrdersByStatuses(
      OrderStatusPresentation.displayOrder, // UIの表示順序を直接利用
      userId,
    );

    // lib/features/order/presentation/pages/order_status_page.dart
    import "../../shared/order_status_presentation.dart";
    // ...
    _OrderStatusSection(
      title: OrderStatusPresentation.label(OrderStatus.inProgress), // UIのラベルを直接利用
      //...
    )
    ```
    これらの利用方法は、両ファイルが**プレゼンテーション層に強く依存している**ことを明確に示しています。

-   **改善提案**:
    `lib/features/order/presentation/utils/` というディレクトリを新規に作成し、`order_status_presentation.dart` と `order_status_mapper.dart` をそこへ移動します。これにより、プレゼンテーション層に属するコードが同層内にまとまり、アーキテクチャの責務分離がより明確になります。

## 3. 提案がもたらすメリット

提案されたリファクタリングを実施することで、以下のメリットが期待できます。

-   **凝集度の向上 (Higher Cohesion)**:
    関連するロジックが一つのクラス（例: `OrderService`）に集約されるため、クラスの責務が明確になります。
-   **可読性の向上 (Improved Readability)**:
    開発者が特定の機能を理解するために追跡するファイル数が減り、コードの全体像を把握しやすくなります。
-   **保守性の向上 (Better Maintainability)**:
    変更の影響範囲が単一のクラス内に留まりやすくなり、修正や機能追加が容易かつ安全になります。
-   **アーキテクチャの一貫性 (Architectural Consistency)**:
    ファイルとクラスがその責務に応じた適切な場所に配置されることで、プロジェクト全体のルールが統一され、新規開発者の学習コストが低下します。