import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/app_constants.dart";

import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/cards/app_card.dart";

/// チャートプレースホルダーウィジェット
///
/// 将来のチャートライブラリ統合まで使用
class ChartPlaceholder extends StatelessWidget {
  const ChartPlaceholder({
    required this.title,
    required this.chartType,
    this.height = 300,
    this.description,
    this.data,
    super.key,
  });

  final String title;
  final ChartType chartType;
  final double height;
  final String? description;
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) => AppCard(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ヘッダー
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: AppTextTheme.cardTitle),
                  if (description != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(description!, style: AppTextTheme.cardDescription),
                  ],
                ],
              ),
            ),

            const Divider(),

            // チャートエリア
            Expanded(
              child: Padding(padding: const EdgeInsets.all(16), child: _buildChartContent()),
            ),
          ],
        ),
      ),
    );

  Widget _buildChartContent() {
    if (data != null && data!.isNotEmpty) {
      return _buildVisualPreview();
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(_getChartIcon(), size: 64, color: AppColors.mutedForeground),
          const SizedBox(height: 16),
          Text(
            "${_getChartTypeName()}チャート",
            style: AppTextTheme.cardTitle.copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 8),
          Text("チャートライブラリ統合予定", style: AppTextTheme.cardDescription),
          const SizedBox(height: 8),
          Text("データがありません", style: AppTextTheme.cardDescription),
        ],
      ),
    );
  }

  Widget _buildVisualPreview() {
    switch (chartType) {
      case ChartType.bar:
        return _buildBarChartPreview();
      case ChartType.pie:
        return _buildPieChartPreview();
      case ChartType.line:
      case ChartType.area:
        return _buildLineChartPreview();
      case ChartType.donut:
        return _buildPieChartPreview();
    }
  }

  Widget _buildBarChartPreview() {
    final List<MapEntry<String, dynamic>> entries = data!.entries.toList();
    final double maxValue = entries
        .map((MapEntry<String, dynamic> e) => _extractNumericValue(e.value))
        .reduce((double a, double b) => a > b ? a : b);

    return Column(
      children: <Widget>[
        // 簡易棒グラフ
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: entries.take(5).map((MapEntry<String, dynamic> entry) {
              final double value = _extractNumericValue(entry.value);
              final double height = (value / maxValue) * 120;
              
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      height: height.clamp(10, 120),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _truncateLabel(entry.key),
                      style: AppTextTheme.cardDescription.copyWith(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildDataLegend(),
      ],
    );
  }

  Widget _buildPieChartPreview() {
    final List<MapEntry<String, dynamic>> entries = data!.entries.toList();

    return Column(
      children: <Widget>[
        // 簡易円グラフ（円形のプログレス風）
        Expanded(
          child: Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.muted,
                    ),
                  ),
                  ...entries.take(4).map((MapEntry<String, dynamic> entry) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getSegmentColor(entries.indexOf(entry)),
                          width: 20,
                        ),
                      ),
                    )),
                  Center(
                    child: Text(
                      "${entries.length}項目",
                      style: AppTextTheme.cardDescription.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDataLegend(),
      ],
    );
  }

  Widget _buildLineChartPreview() {
    final List<MapEntry<String, dynamic>> entries = data!.entries.toList();
    
    return Column(
      children: <Widget>[
        // 簡易線グラフ（ドットと線のイメージ）
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: entries.take(6).map((MapEntry<String, dynamic> entry) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _truncateLabel(entry.key),
                    style: AppTextTheme.cardDescription.copyWith(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              )).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildDataLegend(),
      ],
    );
  }

  Widget _buildDataLegend() {
    final List<MapEntry<String, dynamic>> entries = data!.entries.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "データプレビュー:",
            style: AppTextTheme.cardDescription.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...entries.map((MapEntry<String, dynamic> entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "${_truncateLabel(entry.key, maxLength: 20)}: ${entry.value}",
                style: AppTextTheme.cardDescription.copyWith(fontSize: 11),
              ),
            )),
          if (data!.length > 3)
            Text(
              "...他${data!.length - 3}項目",
              style: AppTextTheme.cardDescription.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }


  // ヘルパーメソッド
  double _extractNumericValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    
    // 文字列から数値を抽出 (例: "¥1,000" -> 1000, "45個" -> 45)
    final String stringValue = value.toString();
    final RegExp numRegex = RegExp(AppConstants.numericExtractionPattern);
    final Match? match = numRegex.firstMatch(stringValue);
    
    if (match != null) {
      final String numString = match.group(0)!.replaceAll(AppConstants.commaChar, "");
      return double.tryParse(numString) ?? 0.0;
    }
    
    return 0.0;
  }

  String _truncateLabel(String label, {int maxLength = AppConstants.chartLabelMaxLength}) {
    if (label.length <= maxLength) {
      return label;
    }
    return "${label.substring(0, maxLength)}...";
  }

  Color _getSegmentColor(int index) {
    final List<Color> colors = <Color>[
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
      AppColors.mutedForeground,
    ];
    return colors[index % colors.length];
  }

  IconData _getChartIcon() {
    switch (chartType) {
      case ChartType.line:
        return LucideIcons.trendingUp;
      case ChartType.bar:
        return LucideIcons.barChart4;
      case ChartType.pie:
        return LucideIcons.pieChart;
      case ChartType.area:
        return LucideIcons.areaChart;
      case ChartType.donut:
        return LucideIcons.pieChart;
    }
  }

  String _getChartTypeName() {
    switch (chartType) {
      case ChartType.line:
        return "折れ線";
      case ChartType.bar:
        return "棒";
      case ChartType.pie:
        return "円";
      case ChartType.area:
        return "面";
      case ChartType.donut:
        return "ドーナツ";
    }
  }
}

/// チャート種別
enum ChartType { line, bar, pie, area, donut }

/// 時系列チャート用のデータポイント
class ChartDataPoint {
  const ChartDataPoint({required this.x, required this.y, this.label});

  final DateTime x;
  final double y;
  final String? label;
}

/// カテゴリ別チャート用のデータ
class CategoryData {
  const CategoryData({required this.category, required this.value, this.color});

  final String category;
  final double value;
  final Color? color;
}
