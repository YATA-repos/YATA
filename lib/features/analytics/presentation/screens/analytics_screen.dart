import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/constants.dart";
import "../../../../core/utils/error_handler.dart";
import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/layouts/main_layout.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/buttons/export_button.dart";
import "../../../../shared/widgets/cards/stats_card.dart";
import "../../../../shared/widgets/filters/category_filter.dart";
import "../../../../shared/widgets/forms/date_range_picker.dart";
import "../providers/analytics_providers.dart";
import "../widgets/chart_placeholder.dart";
import "../widgets/log_monitoring_card.dart";

/// 売上分析画面
///
/// 期間別売上分析、チャート表示、データエクスポート機能を提供
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  // フィルター状態
  DateTime? _startDate;
  DateTime? _endDate;
  String _aggregationUnit = "日別";
  List<String> _selectedCategories = <String>[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // デフォルトで過去7日間を設定
    final DateTime now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day);
    _startDate = _endDate!.subtract(const Duration(days: 6));
  }

  @override
  Widget build(BuildContext context) => MainLayout(
      title: AppStrings.titleAnalytics,
      actions: <Widget>[
        // レポート出力ボタン
        ExportButton(onExport: _handleExport, buttonText: "レポート出力"),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 期間選択フィルター
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: _buildFilterSection(),
            ),

            AppLayout.vSpacerMedium,

            // 統計カード
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: _buildStatsSection(),
            ),

            AppLayout.vSpacerLarge,

            // チャートセクション
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: _buildChartsSection(),
            ),

            AppLayout.vSpacerLarge,

            // ログ監視セクション
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: _buildLogMonitoringSection(),
            ),

            AppLayout.vSpacerMedium,
          ],
        ),
      ),
    );

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
        Text("期間選択", style: AppTextTheme.cardTitle),
        AppLayout.vSpacerTiny,
        Text("分析する期間を選択", style: AppTextTheme.cardDescription),

        const SizedBox(height: 20),

        // フィルター行
        ResponsiveHelper.shouldShowSideNavigation(context)
            ? _buildDesktopFilters()
            : _buildMobileFilters(),

        // 適用ボタン
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            AppButton(
              onPressed: _handleApplyFilter,
              text: "適用",
              icon: const Icon(LucideIcons.filter),
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
          label: "期間プリセット",
        ),
      ),

      const SizedBox(width: 20),

      // 集計単位
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("集計単位", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
            AppLayout.vSpacerSmall,
            DropdownButtonFormField<String>(
              value: _aggregationUnit,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _aggregationUnit = value);
                }
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: AppLayout.hBigPaddingSmall,
                fillColor: AppColors.background,
                filled: true,
              ),
              items: <String>["日別", "週別", "月別"].map((String unit) => DropdownMenuItem<String>(value: unit, child: Text(unit))).toList(),
            ),
          ],
        ),
      ),

      const SizedBox(width: 20),

      // 商品カテゴリー
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("商品カテゴリー", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
            AppLayout.vSpacerSmall,
            CategoryFilter(
              selectedCategories: _selectedCategories,
              onSelectionChanged: (List<String> categories) {
                setState(() => _selectedCategories = categories);
              },
              categories: _mockCategoryOptions,
              allowMultipleSelection: true,
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
        label: "期間プリセット",
      ),

      AppLayout.vSpacerDefault,

      // 集計単位と商品カテゴリー
      Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("集計単位", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
                AppLayout.vSpacerSmall,
                DropdownButtonFormField<String>(
                  value: _aggregationUnit,
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _aggregationUnit = value);
                    }
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding: AppLayout.hBigPaddingSmall,
                    fillColor: AppColors.background,
                    filled: true,
                  ),
                  items: <String>["日別", "週別", "月別"].map((String unit) => DropdownMenuItem<String>(value: unit, child: Text(unit))).toList(),
                ),
              ],
            ),
          ),
          AppLayout.hSpacerDefault,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("商品カテゴリー", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
                AppLayout.vSpacerSmall,
                CategoryFilter(
                  selectedCategories: _selectedCategories,
                  onSelectionChanged: (List<String> categories) {
                    setState(() => _selectedCategories = categories);
                  },
                  categories: _mockCategoryOptions,
                  allowMultipleSelection: true,
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  /// 統計セクション
  Widget _buildStatsSection() => ResponsiveHelper.shouldShowSideNavigation(context)
      ? Row(
          children: <Widget>[
            _buildStatsCard(
              "期間合計売上",
              "¥331,050",
              LucideIcons.trendingUp,
              StatsCardVariant.success,
              "前週比 +8.5%",
            ),
            AppLayout.hSpacerDefault,
            _buildStatsCard(
              "平均日次売上",
              "¥41,381",
              LucideIcons.calendar,
              StatsCardVariant.default_,
              "前週比 +5.2%",
            ),
            AppLayout.hSpacerDefault,
            _buildStatsCard(
              "総注文数",
              "187",
              LucideIcons.shoppingCart,
              StatsCardVariant.info,
              "前週比 +12.6%",
            ),
            AppLayout.hSpacerDefault,
            _buildStatsCard(
              "平均客単価",
              "¥1,770",
              LucideIcons.users,
              StatsCardVariant.warning,
              "前週比 -3.8%",
            ),
          ],
        )
      : Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _buildStatsCard(
                  "期間合計売上",
                  "¥331,050",
                  LucideIcons.trendingUp,
                  StatsCardVariant.success,
                  "前週比 +8.5%",
                ),
                AppLayout.hSpacerDefault,
                _buildStatsCard(
                  "平均日次売上",
                  "¥41,381",
                  LucideIcons.calendar,
                  StatsCardVariant.default_,
                  "前週比 +5.2%",
                ),
              ],
            ),
            AppLayout.vSpacerDefault,
            Row(
              children: <Widget>[
                _buildStatsCard(
                  "総注文数",
                  "187",
                  LucideIcons.shoppingCart,
                  StatsCardVariant.info,
                  "前週比 +12.6%",
                ),
                AppLayout.hSpacerDefault,
                _buildStatsCard(
                  "平均客単価",
                  "¥1,770",
                  LucideIcons.users,
                  StatsCardVariant.warning,
                  "前週比 -3.8%",
                ),
              ],
            ),
          ],
        );

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    StatsCardVariant variant,
    String? subtitle,
  ) => Expanded(
    child: StatsCard(title: title, value: value, icon: icon, variant: variant, subtitle: subtitle),
  );

  /// チャートセクション
  Widget _buildChartsSection() => Column(
    children: <Widget>[
      // 日別売上推移
      Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final DateTime endDate = _endDate ?? DateTime.now();
          final DateTime startDate = _startDate ?? endDate.subtract(const Duration(days: 7));
          
          return ref.watch(salesTrendChartDataProvider(startDate, endDate)).when(
            data: (Map<String, dynamic> chartData) => ChartPlaceholder(
              title: "日別売上推移",
              description: "期間内の売上推移",
              chartType: ChartType.line,
              height: 350,
              data: chartData,
            ),
            loading: () => const ChartPlaceholder(
              title: "日別売上推移",
              description: "データを読み込み中...",
              chartType: ChartType.line,
              height: 350,
            ),
            error: (Object error, StackTrace stack) => ChartPlaceholder(
              title: "日別売上推移",
              description: "データの取得に失敗しました: $error",
              chartType: ChartType.line,
              height: 350,
              data: const <String, dynamic>{"エラー": "データなし"},
            ),
          );
        },
      ),

      AppLayout.vSpacerMedium,

      // 商品別売上比較
      Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) => ref.watch(itemSalesChartDataProvider()).when(
            data: (Map<String, dynamic> salesData) => ref.watch(itemQuantityChartDataProvider()).when(
                data: (Map<String, dynamic> quantityData) => ResponsiveHelper.shouldShowSideNavigation(context)
                      ? _buildDesktopCharts(salesData, quantityData)
                      : _buildMobileCharts(salesData, quantityData),
                loading: () => ResponsiveHelper.shouldShowSideNavigation(context)
                    ? _buildDesktopChartsLoading()
                    : _buildMobileChartsLoading(),
                error: (Object error, StackTrace stack) => ResponsiveHelper.shouldShowSideNavigation(context)
                    ? _buildDesktopChartsError(error)
                    : _buildMobileChartsError(error),
              ),
            loading: () => ResponsiveHelper.shouldShowSideNavigation(context)
                ? _buildDesktopChartsLoading()
                : _buildMobileChartsLoading(),
            error: (Object error, StackTrace stack) => ResponsiveHelper.shouldShowSideNavigation(context)
                ? _buildDesktopChartsError(error)
                : _buildMobileChartsError(error),
          ),
      ),

      AppLayout.vSpacerMedium,

      // 時間帯別売上分析（将来実装予定）
      const ChartPlaceholder(
        title: "時間帯別売上分析",
        description: "営業時間内の売上パターン（機能開発中）",
        chartType: ChartType.area,
        data: <String, dynamic>{
          "準備中": "機能開発中",
        },
      ),
    ],
  );

  /// デスクトップ用チャート表示
  Widget _buildDesktopCharts(Map<String, dynamic> salesData, Map<String, dynamic> quantityData) => Row(
    children: <Widget>[
      Expanded(
        child: ChartPlaceholder(
          title: "商品別売上比率",
          description: "商品別の売上構成",
          chartType: ChartType.pie,
          data: salesData,
        ),
      ),
      AppLayout.hSpacerMedium,
      Expanded(
        child: ChartPlaceholder(
          title: "商品別販売数",
          description: "商品別の販売個数",
          chartType: ChartType.bar,
          data: quantityData,
        ),
      ),
    ],
  );

  /// モバイル用チャート表示
  Widget _buildMobileCharts(Map<String, dynamic> salesData, Map<String, dynamic> quantityData) => Column(
    children: <Widget>[
      ChartPlaceholder(
        title: "商品別売上比率",
        description: "商品別の売上構成",
        chartType: ChartType.pie,
        data: salesData,
      ),
      AppLayout.vSpacerMedium,
      ChartPlaceholder(
        title: "商品別販売数",
        description: "商品別の販売個数",
        chartType: ChartType.bar,
        data: quantityData,
      ),
    ],
  );

  /// デスクトップ用ローディング表示
  Widget _buildDesktopChartsLoading() => Row(
    children: <Widget>[
      const Expanded(
        child: ChartPlaceholder(
          title: "商品別売上比率",
          description: "データを読み込み中...",
          chartType: ChartType.pie,
        ),
      ),
      AppLayout.hSpacerMedium,
      const Expanded(
        child: ChartPlaceholder(
          title: "商品別販売数",
          description: "データを読み込み中...",
          chartType: ChartType.bar,
        ),
      ),
    ],
  );

  /// モバイル用ローディング表示
  Widget _buildMobileChartsLoading() => const Column(
    children: <Widget>[
      ChartPlaceholder(
        title: "商品別売上比率",
        description: "データを読み込み中...",
        chartType: ChartType.pie,
      ),
      AppLayout.vSpacerMedium,
      ChartPlaceholder(
        title: "商品別販売数",
        description: "データを読み込み中...",
        chartType: ChartType.bar,
      ),
    ],
  );

  /// デスクトップ用エラー表示
  Widget _buildDesktopChartsError(Object error) => Row(
    children: <Widget>[
      Expanded(
        child: ChartPlaceholder(
          title: "商品別売上比率",
          description: "データの取得に失敗しました",
          chartType: ChartType.pie,
          data: const <String, dynamic>{"エラー": "データなし"},
        ),
      ),
      AppLayout.hSpacerMedium,
      Expanded(
        child: ChartPlaceholder(
          title: "商品別販売数",
          description: "データの取得に失敗しました",
          chartType: ChartType.bar,
          data: const <String, dynamic>{"エラー": "データなし"},
        ),
      ),
    ],
  );

  /// モバイル用エラー表示
  Widget _buildMobileChartsError(Object error) => Column(
    children: <Widget>[
      ChartPlaceholder(
        title: "商品別売上比率",
        description: "データの取得に失敗しました",
        chartType: ChartType.pie,
        data: const <String, dynamic>{"エラー": "データなし"},
      ),
      AppLayout.vSpacerMedium,
      ChartPlaceholder(
        title: "商品別販売数",
        description: "データの取得に失敗しました",
        chartType: ChartType.bar,
        data: const <String, dynamic>{"エラー": "データなし"},
      ),
    ],
  );

  /// ログ監視セクション
  Widget _buildLogMonitoringSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        "システム監視",
        style: AppTextTheme.cardTitle,
      ),
      AppLayout.vSpacerMedium,
      const LogMonitoringCard(),
    ],
  );

  /// フィルター適用
  void _handleApplyFilter() async {
    setState(() => _isLoading = true);

    try {
      // フィルター適用後、統計データをリフレッシュ
      ref.invalidate(todayStatsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("フィルターを適用しました")),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.instance.showRetryableErrorSnackBar(
          context,
          e,
          onRetry: _handleApplyFilter,
          fallbackMessage: "データの取得に失敗しました",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// エクスポート処理
  void _handleExport(ExportFormat format) {
    // エクスポート機能の本格実装は別タスクで実施予定
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${format.name}形式でのエクスポート機能は開発中です"),
        action: SnackBarAction(
          label: "了解",
          onPressed: () {},
        ),
      ),
    );
  }
}

/// モックカテゴリオプション
final List<CategoryOption> _mockCategoryOptions = <CategoryOption>[
  const CategoryOption(value: "すべて", label: "すべて", icon: LucideIcons.package),
  const CategoryOption(value: "ドリンク", label: "ドリンク", icon: LucideIcons.coffee),
  const CategoryOption(value: "フード", label: "フード", icon: LucideIcons.chefHat),
  const CategoryOption(value: "デザート", label: "デザート", icon: LucideIcons.cake),
  const CategoryOption(value: "セット", label: "セット", icon: LucideIcons.package),
];
