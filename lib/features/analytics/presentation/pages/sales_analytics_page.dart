import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/patterns/patterns.dart";
import "../../../export/presentation/pages/data_export_page.dart";
import "../../../settings/presentation/pages/settings_page.dart";

/// 売上分析画面のモック実装。
class SalesAnalyticsPage extends ConsumerWidget {
  /// [SalesAnalyticsPage]を生成する。
  const SalesAnalyticsPage({super.key});

  /// 売上分析画面のルート名。
  static const String routeName = "/analytics";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: YataColorTokens.background,
      appBar: YataAppTopBar(
        navItems: <YataNavItem>[
          YataNavItem(
            label: "注文",
            icon: Icons.shopping_cart_outlined,
            onTap: () => context.go("/order"),
          ),
          YataNavItem(
            label: "注文状況",
            icon: Icons.dashboard_customize_outlined,
            onTap: () => context.go("/order-status"),
          ),
          YataNavItem(
            label: "履歴",
            icon: Icons.receipt_long_outlined,
            onTap: () => context.go("/history"),
          ),
          YataNavItem(
            label: "在庫管理",
            icon: Icons.inventory_2_outlined,
            onTap: () => context.go("/inventory"),
          ),
          YataNavItem(
            label: "メニュー管理",
            icon: Icons.restaurant_menu_outlined,
            onTap: () => context.go("/menu"),
          ),
          const YataNavItem(label: "売上分析", icon: Icons.query_stats_outlined, isActive: true),
        ],
        trailing: <Widget>[
          YataIconButton(
            icon: Icons.refresh,
            tooltip: "売上データの再取得 (モック)",
            onPressed: () => _showMockRefreshMessage(context),
          ),
          YataIconButton(
            icon: Icons.settings,
            onPressed: () => context.go(SettingsPage.routeName),
            tooltip: "設定",
          ),
        ],
      ),
      body: YataPageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: YataSpacingTokens.lg),
            Text("売上分析", style: textTheme.headlineSmall ?? YataTypographyTokens.headlineSmall),
            const SizedBox(height: YataSpacingTokens.sm),
            Text(
              "リアルタイムの売上傾向、人気メニュー、ピーク時間帯などを視覚化するダッシュボードのモックです。",
              style: (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium).copyWith(
                color: YataColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: YataSpacingTokens.xl),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => context.go(DataExportPage.routeName),
                icon: const Icon(Icons.download_outlined),
                label: const Text("CSVエクスポート (開発中)"),
              ),
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double maxWidth = constraints.maxWidth;
                final double horizontalGap = YataSpacingTokens.lg;
                final int columns = maxWidth >= 960
                    ? 3
                    : maxWidth >= 640
                    ? 2
                    : 1;
                final double rawWidth = columns == 1
                    ? maxWidth
                    : (maxWidth - horizontalGap * (columns - 1)) / columns;
                final double cardWidth = rawWidth.clamp(260, maxWidth);

                return Wrap(
                  spacing: horizontalGap,
                  runSpacing: YataSpacingTokens.lg,
                  children: _highlightMetrics
                      .map(
                        (HighlightMetric metric) => SizedBox(
                          width: cardWidth,
                          child: YataHighlightCard(
                            title: metric.title,
                            subtitle: metric.subtitle,
                            progress: metric.progress,
                            progressLabel: metric.progressLabel,
                            accentColor: metric.accentColor,
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: YataSpacingTokens.xl),
            YataSectionCard(
              title: "売上トレンド",
              subtitle: "時間帯ごとの売上推移を表示予定",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const <Widget>[
                  _ChartPlaceholder(title: "日次売上 (直近7日)", description: "ラインチャートの挿入予定"),
                  SizedBox(height: YataSpacingTokens.md),
                  _LegendRow(
                    items: <_LegendItem>[
                      _LegendItem(label: "実績", color: YataColorTokens.primary),
                      _LegendItem(label: "目標", color: YataColorTokens.info),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            YataSectionCard(
              title: "カテゴリ別売上",
              subtitle: "カテゴリ別の売上構成比を表示予定",
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double maxWidth = constraints.maxWidth;
                  final bool isWide = maxWidth >= 880;

                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Expanded(
                        flex: 2,
                        child: _ChartPlaceholder(
                          title: "カテゴリ構成比",
                          description: "円グラフの挿入予定",
                          height: 260,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? YataSpacingTokens.lg : 0,
                        height: isWide ? 0 : YataSpacingTokens.lg,
                      ),
                      const Expanded(flex: 3, child: _RankingPlaceholder()),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            YataSectionCard(
              title: "導入メモ",
              subtitle: "詳細機能の提供に向けて開発中",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.construction_outlined, color: YataColorTokens.warning),
                      const SizedBox(width: YataSpacingTokens.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "売上分析機能は現在準備中です。",
                              style: textTheme.titleSmall ?? YataTypographyTokens.titleSmall,
                            ),
                            const SizedBox(height: YataSpacingTokens.xs),
                            Text(
                              "グラフや指標は今後のアップデートで追加されます。データ連携が完了してからご利用いただけます。",
                              style: (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium)
                                  .copyWith(color: YataColorTokens.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: YataSpacingTokens.md),
                  Container(
                    padding: const EdgeInsets.all(YataSpacingTokens.md),
                    decoration: BoxDecoration(
                      color: YataColorTokens.warningSoft,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(YataRadiusTokens.medium),
                      ),
                      border: Border.all(color: YataColorTokens.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.info_outlined, color: YataColorTokens.warning),
                        const SizedBox(width: YataSpacingTokens.sm),
                        Expanded(
                          child: Text(
                            "この画面はレイアウトのモックです。将来的には期間フィルター、データエクスポート、トレンド通知などを提供予定です。",
                            style: (textTheme.bodySmall ?? YataTypographyTokens.bodySmall).copyWith(
                              color: YataColorTokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: YataSpacingTokens.xl),
          ],
        ),
      ),
    );
  }

  /// モックデータのため更新処理が未実装である旨を通知する。
  void _showMockRefreshMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("売上データの更新は現在準備中です。")));
  }
}

/// ハイライト指標情報。
class HighlightMetric {
  /// [HighlightMetric]を生成する。
  const HighlightMetric({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressLabel,
    required this.accentColor,
  });

  /// 指標タイトル。
  final String title;

  /// 指標のサブタイトル。
  final String subtitle;

  /// 進捗率。
  final double progress;

  /// 進捗ラベル。
  final String progressLabel;

  /// アクセントカラー。
  final Color accentColor;
}

const List<HighlightMetric> _highlightMetrics = <HighlightMetric>[
  HighlightMetric(
    title: "本日の売上",
    subtitle: "前日比 +8.4%",
    progress: 0.72,
    progressLabel: "日次目標 72%",
    accentColor: YataColorTokens.primary,
  ),
  HighlightMetric(
    title: "今週の累計",
    subtitle: "目標達成まで 220,000円",
    progress: 0.54,
    progressLabel: "週間目標 54%",
    accentColor: YataColorTokens.info,
  ),
  HighlightMetric(
    title: "リピート率",
    subtitle: "常連顧客が全体の 34%",
    progress: 0.34,
    progressLabel: "前年同期比 +5.1pt",
    accentColor: YataColorTokens.success,
  ),
];

/// グラフ領域のプレースホルダー。
class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.title, required this.description, this.height = 240});

  final String title;
  final String description;
  final double height;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: textTheme.titleMedium ?? YataTypographyTokens.titleMedium),
        const SizedBox(height: YataSpacingTokens.xs),
        Text(
          description,
          style: (textTheme.bodySmall ?? YataTypographyTokens.bodySmall).copyWith(
            color: YataColorTokens.textSecondary,
          ),
        ),
        const SizedBox(height: YataSpacingTokens.sm),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: YataColorTokens.surfaceAlt,
            borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.large)),
            border: Border.all(color: YataColorTokens.border),
          ),
          child: Center(
            child: Text(
              "チャート未実装",
              style: (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium).copyWith(
                color: YataColorTokens.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 凡例リスト。
class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: YataSpacingTokens.lg,
    runSpacing: YataSpacingTokens.sm,
    children: items
        .map(
          (_LegendItem item) => Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.small)),
                ),
              ),
              const SizedBox(width: YataSpacingTokens.xs),
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodySmall ?? YataTypographyTokens.bodySmall,
              ),
            ],
          ),
        )
        .toList(growable: false),
  );
}

/// 凡例アイテム定義。
class _LegendItem {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

/// ランキング表のプレースホルダー。
class _RankingPlaceholder extends StatelessWidget {
  const _RankingPlaceholder();

  static const List<_RankingRow> _rows = <_RankingRow>[
    _RankingRow(label: "焼き鳥盛り合わせ", value: "売上比率 22%"),
    _RankingRow(label: "牛すじ煮込み", value: "売上比率 18%"),
    _RankingRow(label: "特製ラーメン", value: "売上比率 15%"),
    _RankingRow(label: "生ビール", value: "売上比率 12%"),
    _RankingRow(label: "自家製レモンサワー", value: "売上比率 9%"),
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("人気メニューランキング", style: textTheme.titleMedium ?? YataTypographyTokens.titleMedium),
        const SizedBox(height: YataSpacingTokens.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: YataColorTokens.surfaceAlt,
            borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
            border: Border.all(color: YataColorTokens.border),
          ),
          child: Column(
            children: <Widget>[
              for (int index = 0; index < _rows.length; index++)
                _RankingTile(
                  row: _rows[index],
                  rank: index + 1,
                  showDivider: index != _rows.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankingRow {
  const _RankingRow({required this.label, required this.value});

  final String label;
  final String value;
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.row, required this.rank, required this.showDivider});

  final _RankingRow row;
  final int rank;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: YataSpacingTokens.lg,
            vertical: YataSpacingTokens.md,
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: YataColorTokens.primarySoft,
                child: Text(
                  "$rank",
                  style: (textTheme.labelLarge ?? YataTypographyTokens.labelLarge).copyWith(
                    color: YataColorTokens.primary,
                  ),
                ),
              ),
              const SizedBox(width: YataSpacingTokens.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(row.label, style: textTheme.titleSmall ?? YataTypographyTokens.titleSmall),
                    const SizedBox(height: YataSpacingTokens.xs),
                    Text(
                      row.value,
                      style: (textTheme.bodySmall ?? YataTypographyTokens.bodySmall).copyWith(
                        color: YataColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: YataColorTokens.textTertiary),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: YataColorTokens.border),
      ],
    );
  }
}
