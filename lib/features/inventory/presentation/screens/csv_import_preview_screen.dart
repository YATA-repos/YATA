import "dart:io";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/logging/logger_mixin.dart";

import "../../../../shared/widgets/cards/app_card.dart";
import "../../../../shared/widgets/common/loading_indicator.dart";
import "../../models/inventory_model.dart" as inventory;
import "../../services/csv_import_service.dart";
import "../providers/csv_import_providers.dart";

/// CSVインポートプレビュー画面  
class CSVImportPreviewScreen extends ConsumerStatefulWidget {
  const CSVImportPreviewScreen({super.key});

  @override
  ConsumerState<CSVImportPreviewScreen> createState() => _CSVImportPreviewScreenState();
}

class _CSVImportPreviewScreenState extends ConsumerState<CSVImportPreviewScreen> with LoggerMixin {
  @override
  String get componentName => "CSVImportPreviewScreen";
  File? _selectedFile;
  CSVImportPreview? _previewData;
  bool _isLoading = false;
  String? _errorMessage;

  /// ファイル選択処理
  Future<void> _selectFile() async {
    logDebug("CSVファイル選択を開始");
    try {
      // ここでfile_pickerを使ったファイル選択を実装
      // 今回は簡単な例として、手動でファイルパスを指定
      logDebug("CSVファイル選択機能は開発中です");
    } catch (e, stackTrace) {
      logError("CSVファイル選択中にエラーが発生", e, stackTrace);
      setState(() {
        _errorMessage = "ファイル選択に失敗しました: $e";
      });
    }
  }

  /// CSVプレビュー処理
  Future<void> _previewCSV(File file) async {
    logDebug("CSVプレビューを開始: filePath=${file.path}");
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final CSVImportService service = ref.read(csvImportServiceProvider);
      final CSVImportPreview preview = await service.previewCSVFile(file);
      
      logInfo("CSVプレビューが完了: 総件数=${preview.materials.length}, エラー数=${preview.validationErrors.length}");
      setState(() {
        _previewData = preview;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logError("CSVプレビュー中にエラーが発生: filePath=${file.path}", e, stackTrace);
      setState(() {
        _errorMessage = "CSVプレビューに失敗しました: $e";
        _isLoading = false;
      });
    }
  }

  /// インポート実行処理
  Future<void> _executeImport() async {
    if (_selectedFile == null) {
      logWarning("CSVインポート実行: _selectedFileがnullです");
      return;
    }

    logDebug("CSVインポート実行を開始: filePath=${_selectedFile!.path}");
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final CSVImportService service = ref.read(csvImportServiceProvider);
      final CSVImportResult result = await service.importMaterialsFromCSV(
        _selectedFile!,
        "user-id", // 実際のユーザーIDを取得する必要がある
        skipInvalidRows: true,
      );
      
      logInfo("CSVインポートが完了: 成功=${result.successCount}件, エラー=${result.errorCount}件, hasErrors=${result.hasErrors}");
      
      // インポート完了後の処理
      if (!context.mounted) return;
      
      final BuildContext currentContext = context;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text("インポート完了: ${result.successCount}件成功, ${result.errorCount}件エラー"),
          backgroundColor: result.hasErrors ? Colors.orange : Colors.green,
        ),
      );
      
      if (!result.hasErrors) {
        logDebug("CSVインポートがエラーなしで完了。画面を閉じます");
        if (!currentContext.mounted) return;
        Navigator.of(currentContext).pop();
      }
    } catch (e, stackTrace) {
      logError("CSVインポート中にエラーが発生: filePath=${_selectedFile!.path}", e, stackTrace);
      setState(() {
        _errorMessage = "インポートに失敗しました: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text("CSV材料インポート"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ファイル選択セクション
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "CSVファイル選択",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _selectedFile?.path ?? "ファイルが選択されていません",
                          style: TextStyle(
                            color: _selectedFile != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectFile,
                        icon: const Icon(LucideIcons.upload),
                        label: const Text("選択"),
                      ),
                    ],
                  ),
                  if (_selectedFile != null) ...<Widget>[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _previewCSV(_selectedFile!),
                      icon: const Icon(LucideIcons.eye),
                      label: const Text("プレビュー"),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // エラーメッセージ表示
            if (_errorMessage != null)
              AppCard(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(LucideIcons.alertCircle, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // ローディング表示
            if (_isLoading)
              const AppCard(
                child: Center(
                  child: Column(
                    children: <Widget>[
                      LoadingIndicator(),
                      SizedBox(height: 16),
                      Text("処理中..."),
                    ],
                  ),
                ),
              ),
            
            // プレビューデータ表示
            if (_previewData != null && !_isLoading)
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "プレビュー結果",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 統計情報
                      Row(
                        children: <Widget>[
                          _buildStatCard(
                            "総件数",
                            "${_previewData!.materials.length}",
                            LucideIcons.fileText,
                            Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            "エラー",
                            "${_previewData!.validationErrors.length}",
                            LucideIcons.alertTriangle,
                            Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // エラー一覧（あれば）
                      if (_previewData!.hasValidationErrors) ...<Widget>[
                        const Text(
                          "検証エラー",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _previewData!.validationErrors.length,
                            itemBuilder: (BuildContext context, int index) {
                              final CSVImportError error = _previewData!.validationErrors[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  LucideIcons.alertCircle,
                                  color: Colors.red.shade600,
                                  size: 16,
                                ),
                                title: Text(
                                  error.toString(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // 材料プレビュー
                      const Text(
                        "材料プレビュー",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _previewData!.materials.length,
                            itemBuilder: (BuildContext context, int index) {
                              final inventory.Material material = _previewData!.materials[index];
                              return ListTile(
                                dense: true,
                                title: Text(material.name),
                                subtitle: Text(
                                  "${material.unitType.name} | 在庫: ${material.currentStock}",
                                ),
                                trailing: Icon(
                                  LucideIcons.package,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // インポート実行ボタン
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _previewData!.materials.isNotEmpty ? _executeImport : null,
                          icon: const Icon(LucideIcons.download),
                          label: const Text("インポート実行"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

  /// 統計カードウィジェット
  Widget _buildStatCard(String label, String value, IconData icon, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
}