import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/contracts/export/export_contracts.dart";
import "../../../../shared/components/buttons/icon_button.dart";
import "../../../../shared/components/layout/page_container.dart";
import "../../../../shared/components/layout/section_card.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/patterns/navigation/app_top_bar.dart";
import "../../../settings/presentation/pages/settings_page.dart";
import "../controllers/data_export_controller.dart";

/// Data Export 画面。
class DataExportPage extends ConsumerStatefulWidget {
  const DataExportPage({super.key});

  /// ルート名。
  static const String routeName = "/settings/data-export";

  @override
  ConsumerState<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends ConsumerState<DataExportPage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  bool _progressSheetOpen = false;
  bool _otpSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _handleStateChanged(null, ref.read(dataExportControllerProvider));
      ref.listen<DataExportState>(
        dataExportControllerProvider,
        _handleStateChanged,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final DataExportState state = ref.watch(dataExportControllerProvider);
    final DataExportController controller = ref.read(dataExportControllerProvider.notifier);

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
          YataNavItem(
            label: "売上分析",
            icon: Icons.query_stats_outlined,
            onTap: () => context.go("/analytics"),
          ),
        ],
        trailing: <Widget>[
          YataIconButton(
            icon: Icons.settings,
            tooltip: "設定",
            onPressed: () => context.go(SettingsPage.routeName),
          ),
        ],
      ),
      body: YataPageContainer(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: YataSpacingTokens.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (state.isOffline)
                      _OfflineBanner(onDismissed: controller.refreshQuota),
                    _HeaderSection(state: state, onRefreshQuota: controller.refreshQuota),
                    const SizedBox(height: YataSpacingTokens.lg),
                    FormBuilder(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _DateRangeCard(state: state, onChange: controller.updateDateRange, onOpenPicker: _openDateRangePicker),
                          const SizedBox(height: YataSpacingTokens.lg),
                          _DatasetCard(state: state, onSelect: controller.updateDataset),
                          const SizedBox(height: YataSpacingTokens.lg),
                          _OptionsCard(
                            state: state,
                            onChangeLocation: controller.updateLocation,
                            onToggleIncludeHeaders: controller.updateIncludeHeaders,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: YataSpacingTokens.xl),
                    _ActionSection(
                      state: state,
                      onSubmit: controller.submitExport,
                      onQuotaHelp: controller.refreshQuota,
                    ),
                    const SizedBox(height: YataSpacingTokens.xl),
                    if (state.lastResult != null)
                      _ResultMetadataSection(result: state.lastResult!),
                    const SizedBox(height: YataSpacingTokens.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStateChanged(DataExportState? previous, DataExportState next) {
    if (!mounted) {
      return;
    }

    final bool wasLoading = _shouldShowProgress(previous);
    final bool isLoading = _shouldShowProgress(next);

    if (!wasLoading && isLoading) {
      _openProgressSheet();
    } else if (wasLoading && !isLoading) {
      _closeProgressSheet();
    }

    if (next.status == DataExportStatus.error && next.errorMessage != null) {
      _showSnackBar(next.errorMessage!, isError: true);
    } else if (next.status == DataExportStatus.completed) {
      final String message = next.savedFilePath != null
          ? "CSVを${next.savedFilePath}に保存しました"
          : "CSVの作成が完了しました";
      _showSnackBar(message, isError: false);
    }

    if (next.showOtpSheet && !_otpSheetOpen) {
      _openOtpSheet(next);
    }
  }

  bool _shouldShowProgress(DataExportState? state) {
    if (state == null) {
      return false;
    }
    return state.status == DataExportStatus.preparing ||
        state.status == DataExportStatus.exporting ||
        state.status == DataExportStatus.saving;
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) {
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _openProgressSheet() async {
    if (!mounted || _progressSheetOpen) {
      return;
    }
    _progressSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      builder: (_) => const _ProgressSheet(),
    );
    _progressSheetOpen = false;
  }

  void _closeProgressSheet() {
    if (!mounted || !_progressSheetOpen) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _openOtpSheet(DataExportState state) async {
    final CsvExportResult? result = state.lastResult;
    final String? password = result?.encryption?.password;
    if (result == null || password == null) {
      ref.read(dataExportControllerProvider.notifier).dismissOtpSheet();
      return;
    }

    if (!mounted) {
      return;
    }
    _otpSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => _OtpSheet(
        password: password,
        fileName: result.fileName,
        onClosed: () => ref.read(dataExportControllerProvider.notifier).dismissOtpSheet(),
      ),
    );
    if (mounted) {
      ref.read(dataExportControllerProvider.notifier).dismissOtpSheet();
    }
    _otpSheetOpen = false;
  }

  Future<void> _openDateRangePicker(DataExportState state, void Function(DateTimeRange) onChange) async {
    if (!mounted) {
      return;
    }
    final DateTimeRange initialRange = state.dateRange;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: "期間を選択",
      locale: const Locale("ja"),
      builder: (BuildContext context, Widget? child) => Localizations.override(
        context: context,
        locale: const Locale("ja"),
        child: child,
      ),
    );
    if (picked != null) {
      onChange(picked);
    }
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.state, required this.onRefreshQuota});

  final DataExportState state;
  final Future<void> Function() onRefreshQuota;

  @override
  Widget build(BuildContext context) {
    final DataExportQuota? quota = state.quota;
    final String organizationLabel = state.organizationId ?? "組織情報未取得";
    final String quotaLabel = quota != null
        ? "残り${quota.remaining}/${quota.dailyLimit}件"
        : "残数計算中";

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "データエクスポート",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: YataSpacingTokens.xs),
              Text(
                "組織: $organizationLabel",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (state.selectedLocationId != null)
                Text(
                  "店舗: ${_resolveLocationName(state)}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        Chip(
          avatar: const Icon(Icons.speed_outlined, size: 18),
          label: Text(quotaLabel),
          backgroundColor: YataColorTokens.surface,
        ),
        const SizedBox(width: YataSpacingTokens.sm),
        IconButton(
          tooltip: "レート残数を更新",
          onPressed: onRefreshQuota,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  String _resolveLocationName(DataExportState state) {
    final String? selected = state.selectedLocationId;
    if (selected == null) {
      return "未選択";
    }
    for (final ExportLocationOption option in state.locationOptions) {
      if (option.id == selected) {
        return option.label;
      }
    }
    return selected;
  }
}

class _DateRangeCard extends StatelessWidget {
  const _DateRangeCard({
    required this.state,
    required this.onChange,
    required this.onOpenPicker,
  });

  final DataExportState state;
  final void Function(DateTimeRange) onChange;
  final Future<void> Function(DataExportState, void Function(DateTimeRange)) onOpenPicker;

  @override
  Widget build(BuildContext context) {
    final String rangeLabel = "${_formatDate(state.dateRange.start)} 〜 ${_formatDate(state.dateRange.end)}";

    return YataSectionCard(
      title: "期間を指定",
      subtitle: "JST固定。最大31日間まで選択できます",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(rangeLabel, style: Theme.of(context).textTheme.titleMedium),
            subtitle: const Text("タップして期間を変更"),
            trailing: const Icon(Icons.date_range),
            onTap: () => onOpenPicker(state, onChange),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => "${date.year.toString().padLeft(4, "0")}/${date.month.toString().padLeft(2, "0")}/${date.day.toString().padLeft(2, "0")}";
}

class _DatasetCard extends StatelessWidget {
  const _DatasetCard({required this.state, required this.onSelect});

  final DataExportState state;
  final void Function(CsvExportDataset) onSelect;

  @override
  Widget build(BuildContext context) => YataSectionCard(
      title: "データセット",
      subtitle: "対象となるCSV種類を選択してください",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SegmentedButton<CsvExportDataset>(
            segments: <ButtonSegment<CsvExportDataset>>[
              for (final CsvExportDataset dataset in state.datasetOptions)
                ButtonSegment<CsvExportDataset>(
                  value: dataset,
                  label: Text(_datasetLabel(dataset)),
                  icon: Icon(_datasetIcon(dataset)),
                ),
            ],
            selected: <CsvExportDataset>{state.dataset},
            onSelectionChanged: (Set<CsvExportDataset> value) {
              if (value.isEmpty) {
                return;
              }
              onSelect(value.first);
            },
          ),
          const SizedBox(height: YataSpacingTokens.md),
          Text(
            _datasetDescription(state.dataset),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );

  String _datasetLabel(CsvExportDataset dataset) => switch (dataset) {
        CsvExportDataset.salesLineItems => "注文売上",
        CsvExportDataset.purchasesLineItems => "仕入明細",
        CsvExportDataset.inventoryTransactions => "在庫移動",
        CsvExportDataset.wasteLog => "廃棄ログ",
        CsvExportDataset.menuEngineeringDaily => "メニュー分析",
      };

  IconData _datasetIcon(CsvExportDataset dataset) => switch (dataset) {
        CsvExportDataset.salesLineItems => Icons.receipt_long,
        CsvExportDataset.purchasesLineItems => Icons.shopping_basket_outlined,
        CsvExportDataset.inventoryTransactions => Icons.compare_arrows_outlined,
        CsvExportDataset.wasteLog => Icons.delete_outline,
        CsvExportDataset.menuEngineeringDaily => Icons.insights_outlined,
      };

  String _datasetDescription(CsvExportDataset dataset) => switch (dataset) {
        CsvExportDataset.salesLineItems => "売上伝票のラインアイテム。注文履歴のフィルターが適用されます。",
        CsvExportDataset.purchasesLineItems => "仕入伝票のラインアイテム。仕入カテゴリ別のコスト分析に利用します。",
        CsvExportDataset.inventoryTransactions => "在庫トランザクション。棚卸と差異分析向けの取引履歴です。",
        CsvExportDataset.wasteLog => "廃棄ログ。食品廃棄やロス計測レポートに利用されます。",
        CsvExportDataset.menuEngineeringDaily => "メニュー工学日次集計。売上・原価・貢献度を日次スナップショットで出力します。",
      };
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({
    required this.state,
    required this.onChangeLocation,
    required this.onToggleIncludeHeaders,
  });

  final DataExportState state;
  final void Function(String?) onChangeLocation;
  final void Function(bool) onToggleIncludeHeaders;

  @override
  Widget build(BuildContext context) => YataSectionCard(
      title: "出力オプション",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (state.requiresLocation)
            _LocationDropdown(state: state, onChangeLocation: onChangeLocation)
          else
            const Text("このデータセットは全店舗共通です"),
          const SizedBox(height: YataSpacingTokens.lg),
          SwitchListTile.adaptive(
            value: state.includeHeaders,
            onChanged: onToggleIncludeHeaders,
            title: const Text("ヘッダー行を含める"),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
}

class _LocationDropdown extends StatelessWidget {
  const _LocationDropdown({required this.state, required this.onChangeLocation});

  final DataExportState state;
  final void Function(String?) onChangeLocation;

  @override
  Widget build(BuildContext context) {
    if (state.locationOptions.isEmpty) {
      return const Text("店舗情報が見つかりません。管理者にご確認ください。");
    }

    return DropdownButtonFormField<String>(
      initialValue: state.selectedLocationId,
      onChanged: onChangeLocation,
      decoration: const InputDecoration(labelText: "店舗を選択"),
      items: <DropdownMenuItem<String>>[
        for (final ExportLocationOption option in state.locationOptions)
          DropdownMenuItem<String>(
            value: option.id,
            child: Text(option.label),
          ),
      ],
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.state,
    required this.onSubmit,
    required this.onQuotaHelp,
  });

  final DataExportState state;
  final VoidCallback onSubmit;
  final VoidCallback onQuotaHelp;

  @override
  Widget build(BuildContext context) {
    final bool disabled = !state.canSubmit || (state.quota?.remaining ?? 1) <= 0;
    final Widget button = FilledButton.tonalIcon(
      onPressed: disabled ? null : onSubmit,
      icon: const Icon(Icons.download_outlined),
      label: const Text("CSVをエクスポート"),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        button,
        const SizedBox(height: YataSpacingTokens.sm),
        if ((state.quota?.remaining ?? 1) <= 0)
          TextButton.icon(
            onPressed: onQuotaHelp,
            icon: const Icon(Icons.info_outline),
            label: const Text("レート枠のリセット時刻を確認"),
          ),
      ],
    );
  }
}

class _ResultMetadataSection extends StatelessWidget {
  const _ResultMetadataSection({required this.result});

  final CsvExportResult result;

  @override
  Widget build(BuildContext context) {
    final List<_MetadataItem> items = <_MetadataItem>[
      _MetadataItem(label: "ファイル名", value: result.fileName),
      _MetadataItem(label: "データセット", value: result.dataset.id),
      _MetadataItem(
        label: "作成日時",
        value: result.generatedAt.toLocal().toString(),
      ),
      if (result.rowCount != null)
        _MetadataItem(label: "レコード数", value: result.rowCount.toString()),
      if (result.exportJobId != null)
        _MetadataItem(label: "ジョブID", value: result.exportJobId!),
      if (result.generatedByAppVersion != null)
        _MetadataItem(label: "アプリバージョン", value: result.generatedByAppVersion!),
    ];

    return YataSectionCard(
      title: "直近のエクスポート",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final _MetadataItem item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: YataSpacingTokens.xs),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 140,
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: YataColorTokens.textSecondary,
                          ),
                    ),
                  ),
                  Expanded(child: Text(item.value)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetadataItem {
  const _MetadataItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) => MaterialBanner(
        content: const Text("オフラインです。オンラインに戻ったら再度お試しください。"),
        leading: const Icon(Icons.wifi_off_outlined),
        backgroundColor: Colors.orange.shade100,
        actions: <Widget>[
          TextButton(onPressed: onDismissed, child: const Text("再確認")),
        ],
      );
}

class _ProgressSheet extends ConsumerWidget {
  const _ProgressSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DataExportState state = ref.watch(dataExportControllerProvider);
    final String message = state.progressMessage ?? "処理中です…";

    return Padding(
      padding: const EdgeInsets.all(YataSpacingTokens.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(width: YataSpacingTokens.md),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: YataSpacingTokens.md),
          const Text("暗号化ZIP生成中は数秒かかる場合があります。"),
        ],
      ),
    );
  }
}

class _OtpSheet extends StatelessWidget {
  const _OtpSheet({required this.password, required this.fileName, required this.onClosed});

  final String password;
  final String fileName;
  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(YataSpacingTokens.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "暗号化ZIPのパスワード",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: YataSpacingTokens.md),
          SelectableText(
            password,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: YataSpacingTokens.sm),
          Text("ファイル: $fileName"),
          const SizedBox(height: YataSpacingTokens.lg),
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: password));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("クリップボードにコピーしました")),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text("コピー"),
              ),
              const SizedBox(width: YataSpacingTokens.md),
              OutlinedButton.icon(
                onPressed: () => _showQrDialog(context, password),
                icon: const Icon(Icons.qr_code_2_outlined),
                label: const Text("QR表示"),
              ),
              const SizedBox(width: YataSpacingTokens.md),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onClosed();
                },
                child: const Text("閉じる"),
              ),
            ],
          ),
        ],
      ),
    );

  static Future<void> _showQrDialog(BuildContext context, String data) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("パスワードQR"),
        content: SelectableText(data),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("閉じる")),
        ],
      ),
    );
  }
}
