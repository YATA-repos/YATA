import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../app/wiring/provider.dart" show settingsServiceProvider;
import "../../../../infra/logging/log_level.dart";
import "../../../../shared/components/buttons/icon_button.dart";
import "../../../../shared/components/layout/page_container.dart";
import "../../../../shared/components/layout/section_card.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/patterns/patterns.dart";
import "../../../export/presentation/pages/data_export_page.dart";
import "../../domain/app_settings.dart";
import "../controllers/settings_controller.dart";

/// 設定画面。
class SettingsPage extends ConsumerStatefulWidget {
  /// [SettingsPage]を生成する。
  const SettingsPage({super.key});

  /// ルート名。
  static const String routeName = "/settings";

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _taxRateController;
  late final Future<String> _defaultLogDirectoryFuture;
  late final ProviderSubscription<SettingsFormState> _formStateSubscription;

  @override
  void initState() {
    super.initState();
    final SettingsFormState formState = ref.read(settingsFormProvider);
    _taxRateController = TextEditingController(text: formState.taxRateText);
    _defaultLogDirectoryFuture = ref.read(settingsServiceProvider).resolveDefaultLogDirectory();

    _formStateSubscription = ref.listenManual<SettingsFormState>(
      settingsFormProvider,
      _handleFormStateChanged,
    );
  }

  @override
  void dispose() {
    _formStateSubscription.close();
    _taxRateController.dispose();
    super.dispose();
  }

  void _handleFormStateChanged(SettingsFormState? previous, SettingsFormState next) {
    if (previous?.taxRateText == next.taxRateText) {
      return;
    }
    if (_taxRateController.text == next.taxRateText) {
      return;
    }
    _taxRateController.value = _taxRateController.value.copyWith(
      text: next.taxRateText,
      selection: TextSelection.collapsed(offset: next.taxRateText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState state = ref.watch(settingsControllerProvider);
    final SettingsFormState formState = ref.watch(settingsFormProvider);
    final SettingsController controller = ref.read(settingsControllerProvider.notifier);

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
            icon: Icons.refresh,
            tooltip: "設定を再読み込み",
            onPressed: state.isLoading ? null : controller.refresh,
          ),
        ],
      ),
      body: YataPageContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: YataSpacingTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: YataSpacingTokens.md),
                  child: LinearProgressIndicator(),
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: YataSpacingTokens.md),
                  child: _ErrorBanner(message: state.error.toString()),
                ),
              _OverviewSection(state: state),
              const SizedBox(height: YataSpacingTokens.lg),
              _AccountSection(
                controller: controller,
                formState: formState,
                status: state.logoutStatus,
              ),
              const SizedBox(height: YataSpacingTokens.lg),
              _DebugSection(controller: controller, state: state),
              const SizedBox(height: YataSpacingTokens.lg),
              _TaxSection(
                controller: controller,
                formState: formState,
                status: state.taxStatus,
                textController: _taxRateController,
                settings: state.settings,
              ),
              const SizedBox(height: YataSpacingTokens.lg),
              _LogDirectorySection(
                controller: controller,
                status: state.logDirectoryStatus,
                settings: state.settings,
                defaultDirectoryFuture: _defaultLogDirectoryFuture,
                onPickDirectory: () => _pickLogDirectory(controller),
              ),
              const SizedBox(height: YataSpacingTokens.lg),
              const _DataExportShortcut(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLogDirectory(SettingsController controller) async {
    final String? directoryPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "ログ保存先を選択",
    );
    if (!mounted || directoryPath == null) {
      return;
    }
    await controller.chooseLogDirectory(directoryPath);
  }
}

class _DataExportShortcut extends StatelessWidget {
  const _DataExportShortcut();

  @override
  Widget build(BuildContext context) => YataSectionCard(
        title: "データエクスポート",
        subtitle: "CSV出力の管理・履歴確認はこちら",
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.file_download_outlined),
          title: const Text("CSVエクスポートセンターを開く"),
          subtitle: const Text("注文・仕入・在庫など5種類のCSVを出力します"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(DataExportPage.routeName),
        ),
      );
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = state.settings;
    final TextStyle labelStyle = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: YataColorTokens.textSecondary);
    final TextStyle valueStyle = Theme.of(context).textTheme.bodyLarge!;

    return YataSectionCard(
      title: "現在の設定",
      subtitle: "アプリで有効な主要な設定値のサマリー",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SummaryRow(
            icon: Icons.psychology_alt_outlined,
            label: "デベロッパーモード",
            value: settings.debug.developerMode ? "ON" : "OFF",
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          const SizedBox(height: YataSpacingTokens.sm),
          _SummaryRow(
            icon: Icons.timeline_outlined,
            label: "ログレベル",
            value: settings.debug.globalLogLevel.labelUpper,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          const SizedBox(height: YataSpacingTokens.sm),
          _SummaryRow(
            icon: Icons.percent_outlined,
            label: "消費税率",
            value: "${(settings.taxRate * 100).toStringAsFixed(2)}%",
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          const SizedBox(height: YataSpacingTokens.sm),
          _SummaryRow(
            icon: Icons.folder_copy_outlined,
            label: "ログ保存先",
            value: settings.logDirectory == null || settings.logDirectory!.isEmpty
                ? "アプリ既定のディレクトリ"
                : settings.logDirectory!,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
            enableTooltip: true,
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.controller, required this.formState, required this.status});

  final SettingsController controller;
  final SettingsFormState formState;
  final AsyncValue<void> status;

  @override
  Widget build(BuildContext context) {
    final Object? error = status.whenOrNull(error: (Object error, StackTrace stackTrace) => error);

    return YataSectionCard(
      title: "アカウント",
      subtitle: "セッションとログアウトを管理します",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text("全端末からサインアウトする"),
            subtitle: const Text("不正なログインが疑われる場合などに使用してください"),
            value: formState.signOutAllDevices,
            onChanged: status.isLoading
                ? null
                : (bool? value) {
                    if (value != null) {
                      controller.updateSignOutAllDevices(value);
                    }
                  },
          ),
          const SizedBox(height: YataSpacingTokens.sm),
          FilledButton.icon(
            onPressed: status.isLoading ? null : controller.signOut,
            icon: status.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: const Text("サインアウト"),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: YataSpacingTokens.sm),
              child: Text(
                "サインアウトに失敗しました: ${error.toString()}",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: YataColorTokens.danger),
              ),
            ),
        ],
      ),
    );
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection({required this.controller, required this.state});

  final SettingsController controller;
  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> status = state.debugStatus;
    final Object? error = status.whenOrNull(error: (Object error, StackTrace stackTrace) => error);

    return YataSectionCard(
      title: "デバッグ・ログ設定",
      subtitle: "開発者向けのオプションとログ出力レベルを制御します",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text("デベロッパーモード"),
            subtitle: const Text("有効化すると追加のデバッグ機能や詳細ログが表示されます"),
            value: state.settings.debug.developerMode,
            onChanged: status.isLoading ? null : controller.setDeveloperMode,
          ),
          const SizedBox(height: YataSpacingTokens.sm),
          DropdownMenu<LogLevel>(
            initialSelection: state.settings.debug.globalLogLevel,
            label: const Text("グローバルログレベル"),
            enabled: !status.isLoading,
            dropdownMenuEntries: LogLevel.values
                .map(
                  (LogLevel level) =>
                      DropdownMenuEntry<LogLevel>(value: level, label: level.labelUpper),
                )
                .toList(),
            onSelected: (LogLevel? level) {
              if (level != null) {
                controller.setLogLevel(level);
              }
            },
          ),
          if (status.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: YataSpacingTokens.sm),
              child: LinearProgressIndicator(),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: YataSpacingTokens.sm),
              child: Text(
                "ログ設定の更新に失敗しました: ${error.toString()}",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: YataColorTokens.danger),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaxSection extends StatelessWidget {
  const _TaxSection({
    required this.controller,
    required this.formState,
    required this.status,
    required this.textController,
    required this.settings,
  });

  final SettingsController controller;
  final SettingsFormState formState;
  final AsyncValue<void> status;
  final TextEditingController textController;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final Object? error = status.whenOrNull(error: (Object error, StackTrace stackTrace) => error);
    final bool isPresetEight = (settings.taxRate - 0.08).abs() < 0.0001;
    final bool isPresetTen = (settings.taxRate - 0.10).abs() < 0.0001;

    return YataSectionCard(
      title: "消費税率",
      subtitle: "メニュー価格や注文計算に即時反映されます",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: textController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp("[0-9.,％%]")),
            ],
            enabled: !status.isLoading,
            decoration: const InputDecoration(
              labelText: "消費税率 (%)",
              hintText: "例: 10",
              border: OutlineInputBorder(),
            ),
            onChanged: controller.handleTaxFieldChanged,
            onSubmitted: controller.submitTaxRate,
          ),
          if (formState.validationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
              child: Text(
                formState.validationMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: YataColorTokens.danger),
              ),
            ),
          const SizedBox(height: YataSpacingTokens.sm),
          Wrap(
            spacing: YataSpacingTokens.sm,
            runSpacing: YataSpacingTokens.sm,
            children: <Widget>[
              ChoiceChip(
                label: const Text("8%"),
                selected: isPresetEight,
                onSelected: status.isLoading
                    ? null
                    : (_) {
                        controller.applyPresetTaxRate(8);
                      },
              ),
              ChoiceChip(
                label: const Text("10%"),
                selected: isPresetTen,
                onSelected: status.isLoading
                    ? null
                    : (_) {
                        controller.applyPresetTaxRate(10);
                      },
              ),
            ],
          ),
          const SizedBox(height: YataSpacingTokens.sm),
          FilledButton.icon(
            onPressed: status.isLoading
                ? null
                : () => controller.submitTaxRate(textController.text),
            icon: status.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text("税率を保存"),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: YataSpacingTokens.sm),
              child: Text(
                "税率の更新に失敗しました: ${error.toString()}",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: YataColorTokens.danger),
              ),
            ),
        ],
      ),
    );
  }
}

class _LogDirectorySection extends StatelessWidget {
  const _LogDirectorySection({
    required this.controller,
    required this.status,
    required this.settings,
    required this.defaultDirectoryFuture,
    required this.onPickDirectory,
  });

  final SettingsController controller;
  final AsyncValue<void> status;
  final AppSettings settings;
  final Future<String> defaultDirectoryFuture;
  final Future<void> Function() onPickDirectory;

  @override
  Widget build(BuildContext context) {
    final Object? error = status.whenOrNull(error: (Object error, StackTrace stackTrace) => error);
    final bool hasCustomDirectory =
        settings.logDirectory != null && settings.logDirectory!.isNotEmpty;

    return YataSectionCard(
      title: "ログ保存先",
      subtitle: "ログファイルを保存するディレクトリを設定します",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DirectoryInfo(
            hasCustomDirectory: hasCustomDirectory,
            directory: settings.logDirectory,
            defaultDirectoryFuture: defaultDirectoryFuture,
          ),
          const SizedBox(height: YataSpacingTokens.sm),
          Wrap(
            spacing: YataSpacingTokens.sm,
            runSpacing: YataSpacingTokens.sm,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: status.isLoading ? null : onPickDirectory,
                icon: const Icon(Icons.folder_open),
                label: const Text("フォルダを選択"),
              ),
              OutlinedButton.icon(
                onPressed: status.isLoading || !hasCustomDirectory
                    ? null
                    : controller.resetLogDirectory,
                icon: const Icon(Icons.refresh),
                label: const Text("デフォルトに戻す"),
              ),
            ],
          ),
          if (status.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: YataSpacingTokens.sm),
              child: LinearProgressIndicator(),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: YataSpacingTokens.sm),
              child: Text(
                "ログ保存先の更新に失敗しました: ${error.toString()}",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: YataColorTokens.danger),
              ),
            ),
        ],
      ),
    );
  }
}

class _DirectoryInfo extends StatelessWidget {
  const _DirectoryInfo({
    required this.hasCustomDirectory,
    required this.directory,
    required this.defaultDirectoryFuture,
  });

  final bool hasCustomDirectory;
  final String? directory;
  final Future<String> defaultDirectoryFuture;

  @override
  Widget build(BuildContext context) {
    if (hasCustomDirectory && directory != null) {
      return _DirectoryCard(label: "現在の保存先", path: directory!);
    }

    return FutureBuilder<String>(
      future: defaultDirectoryFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final String path = snapshot.data ?? "解決中...";
        return _DirectoryCard(
          label: "現在の保存先 (既定)",
          path: path,
          isLoading: snapshot.connectionState != ConnectionState.done,
        );
      },
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.label, required this.path, this.isLoading = false});

  final String label;
  final String path;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: YataRadiusTokens.borderRadiusCard,
        border: Border.all(color: YataColorTokens.border),
        color: YataColorTokens.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(YataSpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            Tooltip(
              message: path,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.folder, size: 20),
                  const SizedBox(width: YataSpacingTokens.xs),
                  Expanded(
                    child: Text(path, style: textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(left: YataSpacingTokens.xs),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    this.enableTooltip = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final bool enableTooltip;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      children: <Widget>[
        Icon(icon, color: YataColorTokens.textSecondary),
        const SizedBox(width: YataSpacingTokens.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: labelStyle),
              const SizedBox(height: YataSpacingTokens.xs),
              Text(value, style: valueStyle, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );

    if (!enableTooltip) {
      return content;
    }

    return Tooltip(message: value, child: content);
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: YataRadiusTokens.borderRadiusCard,
        color: YataColorTokens.danger.withValues(alpha: 0.1),
        border: Border.all(color: YataColorTokens.danger),
      ),
      child: Padding(
        padding: const EdgeInsets.all(YataSpacingTokens.md),
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline, color: YataColorTokens.danger),
            const SizedBox(width: YataSpacingTokens.sm),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(color: YataColorTokens.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
