import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";
import "app_button.dart";

/// エクスポートボタンウィジェット
///
/// CSV、Excel、PDFなどの形式でのエクスポート機能を提供
class ExportButton extends StatelessWidget {
  const ExportButton({
    required this.onExport,
    this.formats = const <ExportFormat>[ExportFormat.csv, ExportFormat.excel, ExportFormat.pdf],
    this.buttonText = "エクスポート",
    this.variant = ButtonVariant.outline,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.disabled = false,
    super.key,
  });

  final void Function(ExportFormat format) onExport;
  final List<ExportFormat> formats;
  final String buttonText;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    if (formats.isEmpty) {
      return const SizedBox.shrink();
    }

    if (formats.length == 1) {
      // 単一フォーマットの場合は通常のボタン
      return AppButton(
        onPressed: disabled || isLoading ? null : () => onExport(formats.first),
        variant: variant,
        size: size,
        text: "$buttonText (${formats.first.extension.toUpperCase()})",
        icon: Icon(_getFormatIcon(formats.first)),
        isLoading: isLoading,
      );
    }

    // 複数フォーマットの場合はドロップダウンメニュー
    return PopupMenuButton<ExportFormat>(
      onSelected: onExport,
      enabled: !disabled && !isLoading,
      itemBuilder: (BuildContext context) => formats.map((ExportFormat format) => PopupMenuItem<ExportFormat>(
          value: format,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(_getFormatIcon(format), size: 16, color: _getFormatColor(format)),
              const SizedBox(width: 8),
              Text(format.displayName),
            ],
          ),
        )).toList(),
      child: AppButton(
        onPressed: disabled || isLoading ? null : () {},
        variant: variant,
        size: size,
        text: buttonText,
        icon: const Icon(LucideIcons.download),
        isLoading: isLoading,
      ),
    );
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return LucideIcons.fileText;
      case ExportFormat.excel:
        return LucideIcons.fileSpreadsheet;
      case ExportFormat.pdf:
        return LucideIcons.file;
      case ExportFormat.json:
        return LucideIcons.braces;
    }
  }

  Color _getFormatColor(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return AppColors.success;
      case ExportFormat.excel:
        return AppColors.primary;
      case ExportFormat.pdf:
        return AppColors.danger;
      case ExportFormat.json:
        return AppColors.warning;
    }
  }
}

/// エクスポート形式
enum ExportFormat {
  csv("csv", "CSV", "テキスト形式（カンマ区切り）"),
  excel("xlsx", "Excel", "Microsoft Excel形式"),
  pdf("pdf", "PDF", "PDF文書形式"),
  json("json", "JSON", "JSON形式");

  const ExportFormat(this.extension, this.displayName, this.description);

  final String extension;
  final String displayName;
  final String description;
}

/// エクスポート設定ダイアログ
class ExportSettingsDialog extends StatefulWidget {
  const ExportSettingsDialog({
    required this.formats,
    this.defaultFormat = ExportFormat.csv,
    this.showDateRange = false,
    this.includeFilters = false,
    super.key,
  });

  final List<ExportFormat> formats;
  final ExportFormat defaultFormat;
  final bool showDateRange;
  final bool includeFilters;

  @override
  State<ExportSettingsDialog> createState() => _ExportSettingsDialogState();

  static Future<ExportSettings?> show(
    BuildContext context, {
    required List<ExportFormat> formats,
    ExportFormat defaultFormat = ExportFormat.csv,
    bool showDateRange = false,
    bool includeFilters = false,
  }) => showDialog<ExportSettings>(
      context: context,
      builder: (BuildContext context) => ExportSettingsDialog(
        formats: formats,
        defaultFormat: defaultFormat,
        showDateRange: showDateRange,
        includeFilters: includeFilters,
      ),
    );
}

class _ExportSettingsDialogState extends State<ExportSettingsDialog> {
  late ExportFormat _selectedFormat;
  DateTimeRange? _dateRange;
  bool _includeHeaders = true;
  bool _includeFilters = false;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.defaultFormat;
    _includeFilters = widget.includeFilters;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
      title: const Text("エクスポート設定"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ファイル形式選択
          Text("ファイル形式", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<ExportFormat>(
            value: _selectedFormat,
            onChanged: (ExportFormat? format) {
              if (format != null) {
                setState(() => _selectedFormat = format);
              }
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: widget.formats.map((ExportFormat format) => DropdownMenuItem<ExportFormat>(
                value: format,
                child: Row(
                  children: <Widget>[
                    Icon(_getFormatIcon(format), size: 16, color: _getFormatColor(format)),
                    const SizedBox(width: 8),
                    Text(format.displayName),
                  ],
                ),
              )).toList(),
          ),

          const SizedBox(height: 16),

          // オプション
          Text("オプション", style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),

          CheckboxListTile(
            title: const Text("ヘッダー行を含める"),
            value: _includeHeaders,
            onChanged: (bool? value) {
              setState(() => _includeHeaders = value ?? true);
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          if (widget.includeFilters)
            CheckboxListTile(
              title: const Text("フィルター条件を含める"),
              value: _includeFilters,
              onChanged: (bool? value) {
                setState(() => _includeFilters = value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("キャンセル")),
        AppButton(
          onPressed: _handleExport,
          text: "エクスポート",
          icon: const Icon(LucideIcons.download),
        ),
      ],
    );

  void _handleExport() {
    final ExportSettings settings = ExportSettings(
      format: _selectedFormat,
      dateRange: _dateRange,
      includeHeaders: _includeHeaders,
      includeFilters: _includeFilters,
    );
    Navigator.of(context).pop(settings);
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return LucideIcons.fileText;
      case ExportFormat.excel:
        return LucideIcons.fileSpreadsheet;
      case ExportFormat.pdf:
        return LucideIcons.file;
      case ExportFormat.json:
        return LucideIcons.braces;
    }
  }

  Color _getFormatColor(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return AppColors.success;
      case ExportFormat.excel:
        return AppColors.primary;
      case ExportFormat.pdf:
        return AppColors.danger;
      case ExportFormat.json:
        return AppColors.warning;
    }
  }
}

/// エクスポート設定
class ExportSettings {
  const ExportSettings({
    required this.format,
    this.dateRange,
    this.includeHeaders = true,
    this.includeFilters = false,
  });

  final ExportFormat format;
  final DateTimeRange? dateRange;
  final bool includeHeaders;
  final bool includeFilters;
}
