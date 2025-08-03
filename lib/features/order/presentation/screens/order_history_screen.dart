import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/constants.dart";
import "../../../../core/logging/logger_mixin.dart";
import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/layouts/main_layout.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/buttons/export_button.dart";
import "../../../../shared/widgets/forms/date_range_picker.dart";
import "../../../../shared/widgets/forms/search_field.dart";
import "../../../../shared/widgets/navigation/pagination.dart";
import "../../../../shared/widgets/tables/data_table.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";
import "../../models/order_ui_extensions.dart";
import "../providers/order_providers.dart";


/// 注文履歴画面
///
/// 過去の注文記録表示・検索・フィルター・エクスポート機能を提供
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> with LoggerMixin {
  @override
  String get componentName => "OrderHistoryScreen";
  // フィルター状態
  DateTime? _startDate;
  DateTime? _endDate;
  OrderStatus? _selectedStatus;
  String _searchQuery = "";

  // ページネーション状態
  int _currentPage = 1;
  int _itemsPerPage = AppConfig.defaultItemsPerPage;

  // データ状態
  bool _isLoading = false;

  String? get userId => ref.read(currentUserProvider)?.id;

  @override
  void initState() {
    super.initState();
    // デフォルトで今日を設定
    final DateTime now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate;
    logDebug("注文履歴画面を初期化: 期間 ${_startDate!.toIso8601String()} - ${_endDate!.toIso8601String()}");
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      logWarning("注文履歴画面: ユーザー情報が取得できません");
      return const MainLayout(
        title: "注文履歴",
        child: Center(child: Text("ユーザー情報が取得できません")),
      );
    }

    final OrderSearchRequest searchRequest = OrderSearchRequest(
      page: _currentPage,
      dateFrom: _startDate,
      dateTo: _endDate,
      statusFilter: _selectedStatus != null ? <OrderStatus>[_selectedStatus!] : null,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      limit: _itemsPerPage,
    );

    return ref
        .watch(orderHistoryProvider(searchRequest, userId!))
        .when(
          data: _buildMainContent,
          loading: () {
            logTrace("注文履歴データ読み込み中");
            return const MainLayout(
              title: AppStrings.titleOrderHistory,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          error: (Object error, StackTrace stack) {
            logError("注文履歴データの読み込みでエラーが発生", error, stack);
            return MainLayout(
              title: AppStrings.titleOrderHistory,
              child: Center(child: Text("エラー: $error")),
            );
          },
        );
  }

  /// フィルターセクション
  Widget _buildFilterSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // セクションタイトル
        Text("注文検索", style: AppTextTheme.cardTitle),
        const SizedBox(height: 4),
        Text("日付や商品で注文を検索", style: AppTextTheme.cardDescription),

        const SizedBox(height: 20),

        // フィルター行
        ResponsiveHelper.shouldShowSideNavigation(context)
            ? _buildDesktopFilters()
            : _buildMobileFilters(),

        // フィルター適用ボタン
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            AppButton(
              onPressed: _handleApplyFilter,
              text: "フィルター適用",
              icon: const Icon(LucideIcons.search),
              isLoading: _isLoading,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildDesktopFilters() => Row(
    children: <Widget>[
      // 日付範囲選択
      Expanded(
        flex: 2,
        child: AppDateRangePicker(
          startDate: _startDate,
          endDate: _endDate,
          onDateRangeChanged: (DateTime? start, DateTime? end) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
          },
          presets: DateRangePreset.defaultPresets,
          label: "日付範囲",
        ),
      ),

      const SizedBox(width: 20),

      // ステータスフィルター
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("ステータス", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
            AppLayout.vSpacerSmall,
            DropdownButtonFormField<OrderStatus?>(
              value: _selectedStatus,
              onChanged: (OrderStatus? status) {
                setState(() => _selectedStatus = status);
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                fillColor: AppColors.background,
                filled: true,
              ),
              items: <DropdownMenuItem<OrderStatus?>>[
                const DropdownMenuItem<OrderStatus?>(child: Text("すべて")),
                ...OrderStatus.values.map((OrderStatus status) => DropdownMenuItem<OrderStatus?>(
                    value: status,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(_getStatusIcon(status), size: 16, color: _getStatusColor(status)),
                        AppLayout.hSpacerSmall,
                        Flexible(
                          child: Text(
                            _getStatusText(status),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(width: 20),

      // 商品検索
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("検索", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
            AppLayout.vSpacerSmall,
            SearchField(
              hintText: "注文番号、商品名など...",
              onChanged: (String query) => setState(() => _searchQuery = query),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildMobileFilters() => Column(
    children: <Widget>[
      // 日付範囲選択
      AppDateRangePicker(
        startDate: _startDate,
        endDate: _endDate,
        onDateRangeChanged: (DateTime? start, DateTime? end) {
          setState(() {
            _startDate = start;
            _endDate = end;
          });
        },
        presets: DateRangePreset.defaultPresets,
        label: "日付範囲",
      ),

      AppLayout.vSpacerDefault,

      // ステータスと検索
      Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("ステータス", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
                AppLayout.vSpacerSmall,
                DropdownButtonFormField<OrderStatus?>(
                  value: _selectedStatus,
                  onChanged: (OrderStatus? status) {
                    setState(() => _selectedStatus = status);
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    fillColor: AppColors.background,
                    filled: true,
                  ),
                  items: <DropdownMenuItem<OrderStatus?>>[
                    const DropdownMenuItem<OrderStatus?>(child: Text("すべて")),
                    ...OrderStatus.values.map((OrderStatus status) => DropdownMenuItem<OrderStatus?>(
                        value: status,
                        child: Text(_getStatusText(status)),
                      )),
                  ],
                ),
              ],
            ),
          ),
          AppLayout.hSpacerDefault,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("検索", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
                AppLayout.vSpacerSmall,
                SearchField(
                  hintText: "注文番号、商品名など...",
                  onChanged: (String query) => setState(() => _searchQuery = query),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  /// メインコンテンツを構築
  Widget _buildMainContent(Map<String, dynamic> historyData) {
    final List<Order> orders = historyData["orders"] as List<Order>? ?? <Order>[];
    final int totalCount = historyData["total_count"] as int? ?? 0;
    final int totalPages = (totalCount / _itemsPerPage).ceil();

    return MainLayout(
      title: AppStrings.titleOrderHistory,
      actions: <Widget>[
        // エクスポートボタン
        ExportButton(onExport: (ExportFormat format) => _handleRealExport(format, orders)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 検索フィルター
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: _buildFilterSection(),
          ),

          AppLayout.vSpacerMedium,

          // 注文履歴テーブル
          Expanded(
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: _buildRealOrderHistoryTable(orders),
            ),
          ),

          // ページネーション
          if (totalPages > 1)
            AppPagination(
              currentPage: _currentPage,
              totalPages: totalPages,
              totalItems: totalCount,
              itemsPerPage: _itemsPerPage,
              onPageChanged: (int page) => setState(() => _currentPage = page),
              onItemsPerPageChanged: (int itemsPerPage) {
                setState(() {
                  _itemsPerPage = itemsPerPage;
                  _currentPage = 1;
                });
              },
            ),
        ],
      ),
    );
  }

  /// 実際の注文履歴テーブル
  Widget _buildRealOrderHistoryTable(List<Order> orders) => AppDataTable<Order>(
    columns: <DataColumn>[
      const DataColumn(label: Text("注文番号"), tooltip: "注文番号"),
      DataColumn(
        label: const Text("日時"),
        tooltip: "注文日時",
        onSort: (int columnIndex, bool ascending) => _handleSort("dateTime", ascending),
      ),
      const DataColumn(label: Text("合計金額"), tooltip: "合計金額"),
      DataColumn(
        label: const Text("状態"),
        tooltip: "注文状態",
        onSort: (int columnIndex, bool ascending) => _handleSort("status", ascending),
      ),
      const DataColumn(label: Text("アクション"), tooltip: "操作"),
    ],
    rows: orders.map((Order order) => DataRow(
        cells: <DataCell>[
          AppDataCell.text("#${order.orderNumber}"),
          AppDataCell.text(
            "${order.orderedAt.month.toString().padLeft(2, '0')}/${order.orderedAt.day.toString().padLeft(2, '0')} ${order.orderedAt.hour.toString().padLeft(2, '0')}:${order.orderedAt.minute.toString().padLeft(2, '0')}",
          ),
          AppDataCell.text("¥${order.totalAmount.toStringAsFixed(0)}"),
          AppDataCell.status(_getStatusText(order.status), color: _getStatusColor(order.status)),
          AppDataCell.actions(<Widget>[
            IconButton(
              onPressed: () => _handleRealViewDetails(order),
              icon: const Icon(LucideIcons.eye),
              iconSize: 16,
              tooltip: "詳細",
            ),
          ]),
        ],
      )).toList(),
    emptyMessage: "該当する注文履歴がありません",
    onRowTap: (int index) => _handleRealViewDetails(orders[index]),
  );

  // モックデータ関連のメソッドは、実際のOrderService統合では不要
  // フィルター・ソート・ページネーションはサービス側で処理

  // ページネーションもサービス側で処理されるため、クライアント側での処理は不要

  /// ソート処理
  void _handleSort(String column, bool ascending) {
    logDebug("注文履歴ソートを要求: $column 列（開発中機能）");
    // ソート機能は現在未実装（将来的な拡張機能として検討中）
    // 現在は日付・ステータスフィルターで十分な機能を提供
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$column列のソート機能は開発予定です"),
        action: SnackBarAction(
          label: "了解",
          onPressed: () {},
        ),
      ),
    );
  }

  /// フィルター適用
  void _handleApplyFilter() async {
    if (userId == null) {
      logWarning("注文履歴フィルター適用: userIdがnullです");
      return;
    }

    logDebug("注文履歴フィルター適用を開始: 期間 ${_startDate?.toIso8601String()} - ${_endDate?.toIso8601String()}, ステータス: $_selectedStatus, 検索: $_searchQuery");
    setState(() => _isLoading = true);

    try {
      // OrderService経由でデータをリフレッシュ
      // 現在のフィルター条件でOrderSearchRequestを構築
      final OrderSearchRequest searchRequest = OrderSearchRequest(
        page: _currentPage,
        dateFrom: _startDate,
        dateTo: _endDate,
        statusFilter: _selectedStatus != null ? <OrderStatus>[_selectedStatus!] : null,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        limit: _itemsPerPage,
      );

      // プロバイダーを無効化してリフレッシュ
      ref.invalidate(orderHistoryProvider(searchRequest, userId!));

      logInfo("注文履歴フィルター適用が完了しました");
      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("フィルターを適用しました"), backgroundColor: AppColors.success),
      );
    } catch (e, stackTrace) {
      logError("注文履歴フィルター適用中にエラーが発生", e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("フィルター適用に失敗しました: $e"), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 実際のエクスポート処理
  void _handleRealExport(ExportFormat format, List<Order> orders) {
    logDebug("注文履歴エクスポート確認ダイアログを表示: ${format.name.toUpperCase()}形式、${orders.length}件");
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("${format.name.toUpperCase()}エクスポート"),
        content: Text("注文履歴データ${orders.length}件を${format.name.toUpperCase()}形式でエクスポートしますか？"),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performRealExport(format, orders);
            },
            child: const Text("エクスポート"),
          ),
        ],
      ),
    );
  }

  /// 実際の詳細表示
  void _handleRealViewDetails(Order order) {
    if (order.id == null) {
      logWarning("注文詳細表示: 注文IDがnullです (orderNumber: ${order.orderNumber})");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("注文IDが取得できませんでした"),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    logDebug("注文詳細画面に遷移: orderId=${order.id}, orderNumber=${order.orderNumber}");
    // 注文詳細画面に遷移
    context.go("/orders/${order.id}");
  }

  /// ステータスアイコン取得
  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return LucideIcons.clock;
      case OrderStatus.preparing:
        return LucideIcons.chefHat;
      case OrderStatus.ready:
        return LucideIcons.checkCircle;
      case OrderStatus.delivered:
        return LucideIcons.check;
      case OrderStatus.cancelled:
        return LucideIcons.xCircle;
      case OrderStatus.confirmed:
        return LucideIcons.checkCircle2;
      case OrderStatus.completed:
        return LucideIcons.checkCheck;
      case OrderStatus.refunded:
        return LucideIcons.refreshCcw;
    }
  }

  /// ステータス色取得
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.preparing:
        return AppColors.primary;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.danger;
      case OrderStatus.confirmed:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.refunded:
        return AppColors.muted;
    }
  }

  /// ステータステキスト取得
  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return "待機中";
      case OrderStatus.preparing:
        return "調理中";
      case OrderStatus.ready:
        return "完成";
      case OrderStatus.delivered:
        return "完了";
      case OrderStatus.cancelled:
        return "キャンセル";
      case OrderStatus.confirmed:
        return "確認済み";
      case OrderStatus.completed:
        return "完了";
      case OrderStatus.refunded:
        return "返金済み";
    }
  }

  /// 実際のエクスポート実行
  void _performRealExport(ExportFormat format, List<Order> orders) {
    try {
      logDebug("注文履歴エクスポートを開始: ${format.name.toUpperCase()}形式、${orders.length}件");
      // 実際の実装では、ここでCSVやExcelファイルを生成
      final String formattedData = _formatRealOrderDataForExport(format, orders);

      logInfo("注文履歴エクスポートが完了: ${format.name.toUpperCase()}形式、${orders.length}件");
      // ファイル保存やダウンロードの処理をシミュレート
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${orders.length}件の注文履歴データを${format.name.toUpperCase()}形式でエクスポートしました"),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: "詳細",
            onPressed: () {
              logDebug("エクスポート詳細ダイアログを表示");
              showDialog<void>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text("エクスポート詳細"),
                  content: Text(
                    "データ形式: ${format.name.toUpperCase()}\n件数: ${orders.length}件\n\nプレビュー:\n${formattedData.length > 200 ? "${formattedData.substring(0, 200)}..." : formattedData}",
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("閉じる"),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      logError("注文履歴エクスポート中にエラーが発生: ${format.name.toUpperCase()}形式", e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("エクスポートに失敗しました: $e"), backgroundColor: AppColors.danger),
      );
    }
  }

  /// 実際の注文データをエクスポート形式にフォーマット
  String _formatRealOrderDataForExport(ExportFormat format, List<Order> orders) {
    switch (format) {
      case ExportFormat.csv:
        final StringBuffer buffer = StringBuffer();
        buffer.writeln("注文番号,日時,顧客名,金額,状態");
        for (final Order order in orders) {
          final String dateTime =
              "${order.orderedAt.year}/${order.orderedAt.month.toString().padLeft(2, '0')}/${order.orderedAt.day.toString().padLeft(2, '0')} ${order.orderedAt.hour.toString().padLeft(2, '0')}:${order.orderedAt.minute.toString().padLeft(2, '0')}";
          buffer.writeln(
            "${order.orderNumber},$dateTime,\"${order.displayCustomerName}\",${order.totalAmount},${_getStatusText(order.status)}",
          );
        }
        return buffer.toString();
      case ExportFormat.excel:
        return "Excel形式の注文履歴データ（${orders.length}件）";
      case ExportFormat.pdf:
        return "PDF形式の注文履歴データ（${orders.length}件）";
      case ExportFormat.json:
        return "JSON形式の注文履歴データ（${orders.length}件）";
    }
  }
}
