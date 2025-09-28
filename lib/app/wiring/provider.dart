// DI: アプリ全体の公開プロバイダ集約

import "package:flutter_riverpod/flutter_riverpod.dart";

// Auth
import "../../core/contracts/auth/auth_repository_contract.dart" as auth_contract;
// Batch
import "../../core/contracts/batch/batch_processing_service.dart" as batch_contract;
import "../../core/contracts/cache/cache.dart" as cache_contract;
import "../../core/contracts/logging/logger.dart" as contract;
import "../../core/contracts/realtime/realtime_manager.dart" as r_contract;
// Repository contracts
import "../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../core/contracts/repositories/inventory/inventory_repository_contracts.dart"
    as inv_contract;
import "../../core/contracts/repositories/menu/menu_repository_contracts.dart" as menu_contract;
import "../../core/contracts/repositories/order/order_repository_contracts.dart" as order_contract;
import "../../features/analytics/models/analytics_model.dart" show DailySummary;
import "../../features/analytics/repositories/daily_summary_repository.dart";
import "../../features/analytics/services/analytics_service.dart";
import "../../features/auth/dto/auth_response.dart" as auth_local;
import "../../features/auth/models/user_profile.dart";
import "../../features/auth/repositories/auth_repository.dart";
import "../../features/auth/services/auth_service.dart";
// Feature models
import "../../features/inventory/models/inventory_model.dart"
    show Material, MaterialCategory, Recipe;
import "../../features/inventory/models/supplier_model.dart" show Supplier;
import "../../features/inventory/models/transaction_model.dart"
    show StockAdjustment, StockTransaction, Purchase, PurchaseItem;
import "../../features/inventory/repositories/material_category_repository.dart";
// Feature repositories (implementations)
import "../../features/inventory/repositories/material_repository.dart";
import "../../features/inventory/repositories/purchase_item_repository.dart";
import "../../features/inventory/repositories/purchase_repository.dart";
import "../../features/inventory/repositories/recipe_repository.dart";
import "../../features/inventory/repositories/stock_adjustment_repository.dart";
import "../../features/inventory/repositories/stock_transaction_repository.dart";
import "../../features/inventory/repositories/supplier_repository.dart";
// Services
import "../../features/inventory/services/inventory_service.dart";
import "../../features/inventory/services/material_management_service.dart";
import "../../features/inventory/services/order_stock_service.dart";
import "../../features/inventory/services/stock_level_service.dart";
import "../../features/inventory/services/stock_operation_service.dart";
import "../../features/inventory/services/usage_analysis_service.dart";
import "../../features/menu/models/menu_model.dart" show MenuItem, MenuCategory;
import "../../features/menu/repositories/menu_category_repository.dart";
import "../../features/menu/repositories/menu_item_repository.dart";
import "../../features/menu/services/menu_service.dart";
import "../../features/order/models/order_model.dart" show Order, OrderItem;
import "../../features/order/repositories/order_item_repository.dart";
import "../../features/order/repositories/order_repository.dart";
import "../../features/order/services/cart_management_service.dart";
import "../../features/order/services/cart_service.dart";
import "../../features/order/services/order_calculation_service.dart";
import "../../features/order/services/order_management_service.dart";
import "../../features/order/services/order_service.dart";
import "../../features/order/services/order_stock_service.dart" as order_svc;
import "../../infra/batch/batch_processing_service.dart" as batch_impl;
import "../../infra/local/cache/memory_cache_adapter.dart";
import "../../infra/local/cache/ttl_cache_adapter.dart";
// Infra adapters and concrete repos
import "../../infra/logging/logger_adapter.dart";
import "../../infra/realtime/realtime_manager_adapter.dart";
import "../../infra/repositories/generic_crud_repository.dart";

/// グローバルロガー（契約）
final Provider<contract.LoggerContract> loggerProvider = Provider<contract.LoggerContract>(
  (Ref ref) => const InfraLoggerAdapter(),
);

/// リアルタイムマネージャー（契約）
final Provider<r_contract.RealtimeManagerContract> realtimeManagerProvider =
    Provider<r_contract.RealtimeManagerContract>((Ref ref) => RealtimeManagerAdapter());

/// Inventory: MaterialRepository を契約型で公開
final Provider<inv_contract.MaterialRepositoryContract<Material>> materialRepositoryProvider =
    Provider<inv_contract.MaterialRepositoryContract<Material>>(
      (Ref ref) => MaterialRepository(
        delegate: GenericCrudRepository<Material>(
          ref: ref,
          tableName: "materials",
          fromJson: Material.fromJson,
        ),
      ),
    );

/// Inventory: 他リポジトリ（契約型で公開）
final Provider<inv_contract.MaterialCategoryRepositoryContract<MaterialCategory>>
materialCategoryRepositoryProvider =
    Provider<inv_contract.MaterialCategoryRepositoryContract<MaterialCategory>>(
      (Ref ref) => MaterialCategoryRepository(
        delegate: GenericCrudRepository<MaterialCategory>(
          ref: ref,
          tableName: "material_categories",
          fromJson: MaterialCategory.fromJson,
        ),
      ),
    );
final Provider<inv_contract.RecipeRepositoryContract<Recipe>> recipeRepositoryProvider =
    Provider<inv_contract.RecipeRepositoryContract<Recipe>>(
      (Ref ref) => RecipeRepository(
        delegate: GenericCrudRepository<Recipe>(
          ref: ref,
          tableName: "recipes",
          fromJson: Recipe.fromJson,
        ),
      ),
    );
final Provider<inv_contract.SupplierRepositoryContract<Supplier>> supplierRepositoryProvider =
    Provider<inv_contract.SupplierRepositoryContract<Supplier>>(
      (Ref ref) => SupplierRepository(
        delegate: GenericCrudRepository<Supplier>(
          ref: ref,
          tableName: "suppliers",
          fromJson: Supplier.fromJson,
        ),
      ),
    );
final Provider<inv_contract.StockAdjustmentRepositoryContract<StockAdjustment>>
stockAdjustmentRepositoryProvider =
    Provider<inv_contract.StockAdjustmentRepositoryContract<StockAdjustment>>(
      (Ref ref) => StockAdjustmentRepository(
        delegate: GenericCrudRepository<StockAdjustment>(
          ref: ref,
          tableName: "stock_adjustments",
          fromJson: StockAdjustment.fromJson,
        ),
      ),
    );
final Provider<inv_contract.StockTransactionRepositoryContract<StockTransaction>>
stockTransactionRepositoryProvider =
    Provider<inv_contract.StockTransactionRepositoryContract<StockTransaction>>(
      (Ref ref) => StockTransactionRepository(
        delegate: GenericCrudRepository<StockTransaction>(
          ref: ref,
          tableName: "stock_transactions",
          fromJson: StockTransaction.fromJson,
        ),
      ),
    );
final Provider<inv_contract.PurchaseRepositoryContract<Purchase>> purchaseRepositoryProvider =
    Provider<inv_contract.PurchaseRepositoryContract<Purchase>>(
      (Ref ref) => PurchaseRepository(
        delegate: GenericCrudRepository<Purchase>(
          ref: ref,
          tableName: "purchases",
          fromJson: Purchase.fromJson,
        ),
      ),
    );
final Provider<inv_contract.PurchaseItemRepositoryContract<PurchaseItem>>
purchaseItemRepositoryProvider =
    Provider<inv_contract.PurchaseItemRepositoryContract<PurchaseItem>>(
      (Ref ref) => PurchaseItemRepository(
        delegate: GenericCrudRepository<PurchaseItem>(
          ref: ref,
          tableName: "purchase_items",
          fromJson: PurchaseItem.fromJson,
        ),
      ),
    );

/// Menu: リポジトリ（契約型）
final Provider<menu_contract.MenuItemRepositoryContract<MenuItem>> menuItemRepositoryProvider =
    Provider<menu_contract.MenuItemRepositoryContract<MenuItem>>(
      (Ref ref) => MenuItemRepository(
        delegate: GenericCrudRepository<MenuItem>(
          ref: ref,
          tableName: "menu_items",
          fromJson: MenuItem.fromJson,
        ),
      ),
    );
final Provider<menu_contract.MenuCategoryRepositoryContract<MenuCategory>>
menuCategoryRepositoryProvider =
    Provider<menu_contract.MenuCategoryRepositoryContract<MenuCategory>>(
      (Ref ref) => MenuCategoryRepository(
        delegate: GenericCrudRepository<MenuCategory>(
          ref: ref,
          tableName: "menu_categories",
          fromJson: MenuCategory.fromJson,
        ),
      ),
    );

/// Order: リポジトリ（契約型）
final Provider<order_contract.OrderRepositoryContract<Order>> orderRepositoryProvider =
    Provider<order_contract.OrderRepositoryContract<Order>>(
      (Ref ref) => OrderRepository(
        delegate: GenericCrudRepository<Order>(
          ref: ref,
          tableName: "orders",
          fromJson: Order.fromJson,
        ),
      ),
    );
final Provider<order_contract.OrderItemRepositoryContract<OrderItem>> orderItemRepositoryProvider =
    Provider<order_contract.OrderItemRepositoryContract<OrderItem>>(
      (Ref ref) => OrderItemRepository(
        delegate: GenericCrudRepository<OrderItem>(
          ref: ref,
          tableName: "order_items",
          fromJson: OrderItem.fromJson,
        ),
      ),
    );

/// Analytics: リポジトリ（契約型）
final Provider<repo_contract.CrudRepository<DailySummary, String>>
dailySummaryRawRepositoryProvider = Provider<repo_contract.CrudRepository<DailySummary, String>>(
  (Ref ref) => GenericCrudRepository<DailySummary>(
    ref: ref,
    tableName: "daily_summaries",
    fromJson: DailySummary.fromJson,
  ),
);

/// Analytics: リポジトリ（契約型）
final Provider<DailySummaryRepository> dailySummaryRepositoryProvider =
    Provider<DailySummaryRepository>(
      (Ref ref) => DailySummaryRepository(delegate: ref.read(dailySummaryRawRepositoryProvider)),
    );

/// Cache: Memory / TTL を契約経由で公開
final Provider<cache_contract.Cache<String, dynamic>> memoryCacheProvider =
    Provider<cache_contract.Cache<String, dynamic>>((Ref ref) => MemoryCacheAdapter<dynamic>());
final Provider<cache_contract.Cache<String, dynamic>> ttlCacheProvider =
    Provider<cache_contract.Cache<String, dynamic>>((Ref ref) => TTLCacheAdapter<dynamic>());

/// InventoryService を契約の RealtimeManager で合成して公開
final Provider<InventoryService> inventoryServiceProvider = Provider<InventoryService>((Ref ref) {
  final inv_contract.MaterialRepositoryContract<Material> materialRepo = ref.read(
    materialRepositoryProvider,
  );
  final inv_contract.MaterialCategoryRepositoryContract<MaterialCategory> materialCategoryRepo = ref
      .read(materialCategoryRepositoryProvider);
  final inv_contract.RecipeRepositoryContract<Recipe> recipeRepo = ref.read(
    recipeRepositoryProvider,
  );
  final inv_contract.StockTransactionRepositoryContract<StockTransaction> stockTxRepo = ref.read(
    stockTransactionRepositoryProvider,
  );
  final inv_contract.PurchaseRepositoryContract<Purchase> purchaseRepo = ref.read(
    purchaseRepositoryProvider,
  );
  final inv_contract.PurchaseItemRepositoryContract<PurchaseItem> purchaseItemRepo = ref.read(
    purchaseItemRepositoryProvider,
  );
  final inv_contract.StockAdjustmentRepositoryContract<StockAdjustment> stockAdjRepo = ref.read(
    stockAdjustmentRepositoryProvider,
  );

  final MaterialManagementService materialSvc = MaterialManagementService(
    materialRepository: materialRepo,
    materialCategoryRepository: materialCategoryRepo,
  );
  final StockLevelService stockLevelSvc = StockLevelService(materialRepository: materialRepo);
  final UsageAnalysisService usageSvc = UsageAnalysisService(
    materialRepository: materialRepo,
    stockTransactionRepository: stockTxRepo,
  );
  final OrderStockService orderStockSvc = OrderStockService(
    materialRepository: materialRepo,
    recipeRepository: recipeRepo,
    stockTransactionRepository: stockTxRepo,
    orderItemRepository: ref.read(orderItemRepositoryProvider),
  );
  final StockOperationService stockOpSvc = StockOperationService(
    materialRepository: materialRepo,
    purchaseRepository: purchaseRepo,
    purchaseItemRepository: purchaseItemRepo,
    stockAdjustmentRepository: stockAdjRepo,
    stockTransactionRepository: stockTxRepo,
  );

  return InventoryService(
    ref: ref,
    realtimeManager: ref.read(realtimeManagerProvider),
    materialManagementService: materialSvc,
    stockLevelService: stockLevelSvc,
    usageAnalysisService: usageSvc,
    stockOperationService: stockOpSvc,
    orderStockService: orderStockSvc,
  );
});

final Provider<OrderCalculationService> orderCalculationServiceProvider =
    Provider<OrderCalculationService>(
  (Ref ref) => OrderCalculationService(
    orderItemRepository: ref.read(orderItemRepositoryProvider),
  ),
);

final Provider<order_svc.OrderStockService> orderStockServiceProvider =
    Provider<order_svc.OrderStockService>(
  (Ref ref) => order_svc.OrderStockService(
    materialRepository: ref.read(materialRepositoryProvider),
    recipeRepository: ref.read(recipeRepositoryProvider),
  ),
);

final Provider<CartManagementService> cartManagementServiceProvider =
    Provider<CartManagementService>((Ref ref) => CartManagementService(
    orderRepository: ref.read(orderRepositoryProvider),
    orderItemRepository: ref.read(orderItemRepositoryProvider),
    menuItemRepository: ref.read(menuItemRepositoryProvider),
    orderCalculationService: ref.read(orderCalculationServiceProvider),
    orderStockService: ref.read(orderStockServiceProvider),
  ));

/// OrderService（契約Realtime注入）
final Provider<OrderService> orderServiceProvider = Provider<OrderService>((Ref ref) {
  final OrderManagementService orderMgmt = OrderManagementService(
    orderRepository: ref.read(orderRepositoryProvider),
    orderItemRepository: ref.read(orderItemRepositoryProvider),
    menuItemRepository: ref.read(menuItemRepositoryProvider),
    orderCalculationService: ref.read(orderCalculationServiceProvider),
    orderStockService: ref.read(orderStockServiceProvider),
    cartManagementService: ref.read(cartManagementServiceProvider),
  );
  return OrderService(
    ref: ref,
    realtimeManager: ref.read(realtimeManagerProvider),
    orderManagementService: orderMgmt,
  );
});

/// CartService（注文カート管理）
final Provider<CartService> cartServiceProvider = Provider<CartService>((Ref ref) => CartService(
    cartManagementService: ref.read(cartManagementServiceProvider),
    orderCalculationService: ref.read(orderCalculationServiceProvider),
  ));

/// MenuService（契約Realtime注入）
final Provider<MenuService> menuServiceProvider = Provider<MenuService>(
  (Ref ref) => MenuService(
    ref: ref,
    realtimeManager: ref.read(realtimeManagerProvider),
    menuItemRepository: ref.read(menuItemRepositoryProvider),
    menuCategoryRepository: ref.read(menuCategoryRepositoryProvider),
    materialRepository: ref.read(materialRepositoryProvider),
    recipeRepository: ref.read(recipeRepositoryProvider),
  ),
);

/// Auth: リポジトリ（契約型）
final Provider<auth_contract.AuthRepositoryContract<UserProfile, auth_local.AuthResponse>>
authRepositoryProvider =
    Provider<auth_contract.AuthRepositoryContract<UserProfile, auth_local.AuthResponse>>(
      (Ref ref) => AuthRepository(),
    );

/// Auth: サービス（契約注入）
final Provider<AuthService> authServiceProvider = Provider<AuthService>(
  (Ref ref) => AuthService(authRepository: ref.read(authRepositoryProvider)),
);

/// BatchProcessingService（契約型）
final Provider<batch_contract.BatchProcessingServiceContract> batchProcessingServiceProvider =
    Provider<batch_contract.BatchProcessingServiceContract>(
      (Ref ref) => batch_impl.BatchProcessingService(),
    );

/// AnalyticsService（契約注入）
final Provider<AnalyticsService> analyticsServiceProvider = Provider<AnalyticsService>(
  (Ref ref) => AnalyticsService(
    orderRepository: ref.read(orderRepositoryProvider),
    orderItemRepository: ref.read(orderItemRepositoryProvider),
    stockTransactionRepository: ref.read(stockTransactionRepositoryProvider),
  ),
);
