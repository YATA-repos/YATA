import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";

import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_card.dart";
import "../../../../shared/widgets/common/app_dropdown.dart";
import "../../../../shared/widgets/common/app_loading_indicator.dart";

enum SalesChartType {
  line, // 線グラフ
  bar, // 棒グラフ
  pie, // 円グラフ
}

enum SalesChartPeriod {
  daily, // 日別
  weekly, // 週別
  monthly, // 月別
  yearly, // 年別
}

class SalesChart extends StatefulWidget {
  const SalesChart({
    required this.data,
    super.key,
    this.chartType = SalesChartType.line,
    this.period = SalesChartPeriod.daily,
    this.onChartTypeChanged,
    this.onPeriodChanged,
    this.height = 300,
    this.showControls = true,
    this.showLegend = true,
    this.isLoading = false,
    this.title,
    this.subtitle,
    this.currency = "¥",
  });

  final SalesChartData data;
  final SalesChartType chartType;
  final SalesChartPeriod period;
  final ValueChanged<SalesChartType?>? onChartTypeChanged;
  final ValueChanged<SalesChartPeriod?>? onPeriodChanged;
  final double height;
  final bool showControls;
  final bool showLegend;
  final bool isLoading;
  final String? title;
  final String? subtitle;
  final String currency;

  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(),
        if (widget.showControls) ...<Widget>[
          const SizedBox(height: AppLayout.spacing4),
          _buildControls(),
        ],
        const SizedBox(height: AppLayout.spacing4),
        SizedBox(
          height: widget.height,
          child: widget.isLoading ? _buildLoadingState() : _buildChart(),
        ),
        if (widget.showLegend && !widget.isLoading) ...<Widget>[
          const SizedBox(height: AppLayout.spacing4),
          _buildLegend(),
        ],
      ],
    ),
  );

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (widget.title != null)
        Text(
          widget.title!,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
      if (widget.subtitle != null)
        Text(
          widget.subtitle!,
          style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
        ),
    ],
  );

  Widget _buildControls() => Row(
    children: <Widget>[
      Expanded(
        child: AppDropdown<SalesChartType>(
          value: widget.chartType,
          onChanged: widget.onChartTypeChanged,
          items: SalesChartType.values
              .map(
                (SalesChartType type) => DropdownMenuItem<SalesChartType>(
                  value: type,
                  child: Text(_getChartTypeLabel(type)),
                ),
              )
              .toList(),
          hint: const Text("グラフタイプ"),
        ),
      ),
      const SizedBox(width: AppLayout.spacing4),
      Expanded(
        child: AppDropdown<SalesChartPeriod>(
          value: widget.period,
          onChanged: widget.onPeriodChanged,
          items: SalesChartPeriod.values
              .map(
                (SalesChartPeriod period) => DropdownMenuItem<SalesChartPeriod>(
                  value: period,
                  child: Text(_getPeriodLabel(period)),
                ),
              )
              .toList(),
          hint: const Text("期間"),
        ),
      ),
    ],
  );

  Widget _buildLoadingState() => const Center(child: AppLoadingIndicator(message: "データを読み込み中..."));

  Widget _buildChart() {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    switch (widget.chartType) {
      case SalesChartType.line:
        return _buildLineChart();
      case SalesChartType.bar:
        return _buildBarChart();
      case SalesChartType.pie:
        return _buildPieChart();
    }
  }

  Widget _buildEmptyState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.bar_chart, size: 64, color: AppColors.mutedForeground),
        SizedBox(height: AppLayout.spacing4),
        Text("データがありません", style: TextStyle(fontSize: 16, color: AppColors.mutedForeground)),
      ],
    ),
  );

  Widget _buildLineChart() => Padding(
    padding: AppLayout.padding4,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(
          horizontalInterval: _calculateInterval(widget.data.maxValue),
          verticalInterval: 1,
          getDrawingHorizontalLine: (double value) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
          getDrawingVerticalLine: (double value) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index >= 0 && index < widget.data.labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.data.labels[index],
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                    ),
                  );
                }
                return const Text("");
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateInterval(widget.data.maxValue),
              reservedSize: 60,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                "${widget.currency}${_formatValue(value)}",
                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: AppColors.border)),
        minX: 0,
        maxX: (widget.data.labels.length - 1).toDouble(),
        minY: 0,
        maxY: widget.data.maxValue * 1.1,
        lineBarsData: widget.data.series
            .map(
              (ChartSeries series) => LineChartBarData(
                spots: series.values
                    .asMap()
                    .entries
                    .map((MapEntry<int, double> entry) => FlSpot(entry.key.toDouble(), entry.value))
                    .toList(),
                isCurved: true,
                color: series.color,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: series.color.withValues(alpha: 0.1)),
              ),
            )
            .toList(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) => AppColors.background,
            getTooltipItems: (List<LineBarSpot> touchedSpots) =>
                touchedSpots.map((LineBarSpot touchedSpot) {
                  final int index = touchedSpot.spotIndex;
                  final String label = widget.data.labels[index];
                  final String value = "${widget.currency}${_formatValue(touchedSpot.y)}";

                  return LineTooltipItem(
                    "$label\n$value",
                    const TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
                  );
                }).toList(),
          ),
        ),
      ),
    ),
  );

  Widget _buildBarChart() => Padding(
    padding: AppLayout.padding4,
    child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: widget.data.maxValue * 1.1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (BarChartGroupData group) => AppColors.background,
            getTooltipItem:
                (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) {
                  final String label = widget.data.labels[group.x];
                  final String value = "${widget.currency}${_formatValue(rod.toY)}";

                  return BarTooltipItem(
                    "$label\n$value",
                    const TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
                  );
                },
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index >= 0 && index < widget.data.labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.data.labels[index],
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                    ),
                  );
                }
                return const Text("");
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: _calculateInterval(widget.data.maxValue),
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                "${widget.currency}${_formatValue(value)}",
                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: AppColors.border)),
        barGroups: widget.data.labels.asMap().entries.map((MapEntry<int, String> entry) {
          final int index = entry.key;
          final double value = widget.data.series.isNotEmpty
              ? widget.data.series.first.values[index]
              : 0;

          return BarChartGroupData(
            x: index,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: value,
                color: widget.data.series.isNotEmpty
                    ? widget.data.series.first.color
                    : AppColors.primary,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ),
  );

  Widget _buildPieChart() => Padding(
    padding: AppLayout.padding4,
    child: PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _buildPieSections(),
      ),
    ),
  );

  List<PieChartSectionData> _buildPieSections() {
    final List<PieChartSectionData> sections = <PieChartSectionData>[];
    final double total = widget.data.series.isNotEmpty
        ? widget.data.series.first.values.fold(0, (double sum, double value) => sum + value)
        : 0;

    for (int i = 0; i < widget.data.labels.length; i++) {
      final double value = widget.data.series.isNotEmpty ? widget.data.series.first.values[i] : 0;
      final double percentage = total > 0 ? (value / total) * 100 : 0;
      final bool isTouched = i == _touchedIndex;
      final double radius = isTouched ? 60 : 50;

      sections.add(
        PieChartSectionData(
          color: _getPieColor(i),
          value: value,
          title: "${percentage.toStringAsFixed(1)}%",
          radius: radius,
          titleStyle: TextStyle(
            fontSize: isTouched ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: isTouched ? _buildPieBadge(widget.data.labels[i], value) : null,
          badgePositionPercentageOffset: 1.3,
        ),
      );
    }

    return sections;
  }

  Widget _buildPieBadge(String label, double value) => Container(
    padding: AppLayout.padding2,
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: AppLayout.radiusSm,
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text(
          "${widget.currency}${_formatValue(value)}",
          style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
        ),
      ],
    ),
  );

  Widget _buildLegend() {
    if (widget.chartType == SalesChartType.pie) {
      return _buildPieLegend();
    } else {
      return _buildSeriesLegend();
    }
  }

  Widget _buildSeriesLegend() => Wrap(
    spacing: AppLayout.spacing4,
    runSpacing: AppLayout.spacing2,
    children: widget.data.series
        .map(
          (ChartSeries series) => Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: series.color, borderRadius: AppLayout.radiusSm),
              ),
              const SizedBox(width: AppLayout.spacing1),
              Text(series.name, style: const TextStyle(fontSize: 12, color: AppColors.foreground)),
            ],
          ),
        )
        .toList(),
  );

  Widget _buildPieLegend() => Wrap(
    spacing: AppLayout.spacing4,
    runSpacing: AppLayout.spacing2,
    children: widget.data.labels.asMap().entries.map((MapEntry<int, String> entry) {
      final int index = entry.key;
      final String label = entry.value;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: _getPieColor(index), borderRadius: AppLayout.radiusSm),
          ),
          const SizedBox(width: AppLayout.spacing1),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.foreground)),
        ],
      );
    }).toList(),
  );

  String _getChartTypeLabel(SalesChartType type) {
    switch (type) {
      case SalesChartType.line:
        return "線グラフ";
      case SalesChartType.bar:
        return "棒グラフ";
      case SalesChartType.pie:
        return "円グラフ";
    }
  }

  String _getPeriodLabel(SalesChartPeriod period) {
    switch (period) {
      case SalesChartPeriod.daily:
        return "日別";
      case SalesChartPeriod.weekly:
        return "週別";
      case SalesChartPeriod.monthly:
        return "月別";
      case SalesChartPeriod.yearly:
        return "年別";
    }
  }

  Color _getPieColor(int index) {
    final List<Color> colors = <Color>[
      AppColors.primary,
      AppColors.secondary,
      AppColors.warning,
      AppColors.danger,
      AppColors.accent,
      AppColors.success,
    ];
    return colors[index % colors.length];
  }

  double _calculateInterval(double maxValue) {
    if (maxValue <= 100) {
      return 20;
    }
    if (maxValue <= 1000) {
      return 200;
    }
    if (maxValue <= 10000) {
      return 2000;
    }
    return maxValue / 5;
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

class SalesChartData {
  const SalesChartData({required this.labels, required this.series});

  final List<String> labels;
  final List<ChartSeries> series;

  bool get isEmpty => labels.isEmpty || series.isEmpty;

  double get maxValue {
    if (series.isEmpty) {
      return 0;
    }
    return series
        .expand((ChartSeries series) => series.values)
        .fold(0, (double max, double value) => value > max ? value : max);
  }
}

class ChartSeries {
  const ChartSeries({required this.name, required this.values, required this.color});

  final String name;
  final List<double> values;
  final Color color;
}
