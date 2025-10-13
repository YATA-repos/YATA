import "dart:io";

import "package:file_selector/file_selector.dart";
import "package:flutter/foundation.dart";
import "package:path_provider/path_provider.dart";
import "package:share_plus/share_plus.dart";

import "../../../../core/contracts/export/export_contracts.dart";
import "../../../../core/contracts/logging/logger.dart";
import "../../../../core/logging/levels.dart";

/// CSVファイル保存処理の結果。
class CsvFileSaveSummary {
  const CsvFileSaveSummary({
    required this.saved,
    this.path,
    this.openedShareSheet = false,
  });

  final bool saved;
  final String? path;
  final bool openedShareSheet;
}

/// CSVファイル保存時の例外。
class CsvFileSaveException implements Exception {
  const CsvFileSaveException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => "CsvFileSaveException($message)";
}

/// プラットフォームごとのファイル保存を吸収するヘルパー。
class CsvExportFileSaver {
  CsvExportFileSaver({required LoggerContract logger}) : _logger = logger;

  final LoggerContract _logger;

  Future<CsvFileSaveSummary> save(CsvExportResult result) async {
    if (kIsWeb) {
      throw const CsvFileSaveException("WebプラットフォームではCSV保存をサポートしていません");
    }

    if (Platform.isAndroid || Platform.isIOS) {
      return _saveForMobile(result);
    }
    if (Platform.isWindows) {
      return _saveForDesktop(result);
    }
    if (Platform.isMacOS || Platform.isLinux) {
      return _saveForDesktop(result);
    }

    return _saveToTemporary(result);
  }

  Future<CsvFileSaveSummary> _saveForMobile(CsvExportResult result) async {
    final File file = await _writeToPreferredMobilePath(result);

    try {
      await Share.shareXFiles(
        <XFile>[XFile(file.path, mimeType: result.contentType, name: result.fileName)],
        text: result.encryption?.required ?? false
            ? "暗号化ZIPのパスワードを控えてから保存してください"
            : "CSVを保存してください",
      );
    } on Object catch (error, stackTrace) {
      _logger.log(
        Level.warn,
        "共有ダイアログの呼び出しに失敗",
        tag: "CsvExportFileSaver",
        error: error,
        st: stackTrace,
      );
      throw CsvFileSaveException("共有ダイアログの起動に失敗しました", cause: error);
    }

    return CsvFileSaveSummary(saved: true, path: file.path, openedShareSheet: true);
  }

  Future<File> _writeToPreferredMobilePath(CsvExportResult result) async {
    final List<int> bytes = result.bytes;
    final File? preferredDownload = await _tryAndroidDownloadsPath(result.fileName);
    if (preferredDownload != null) {
      try {
        await preferredDownload.writeAsBytes(bytes, flush: true);
        return preferredDownload;
      } on Object catch (error, stackTrace) {
        _logger.log(
          Level.warn,
          "外部ストレージへの書き込みに失敗",
          tag: "CsvExportFileSaver",
          error: error,
          st: stackTrace,
        );
      }
    }

    final Directory directory = await getTemporaryDirectory();
    final File fallback = File("${directory.path}/${result.fileName}");
    await fallback.writeAsBytes(bytes, flush: true);
    return fallback;
  }

  Future<File?> _tryAndroidDownloadsPath(String fileName) async {
    if (!Platform.isAndroid) {
      return null;
    }

    final Directory downloads = Directory("/storage/emulated/0/Download/yata/exports");
    if (!await downloads.exists()) {
      try {
        await downloads.create(recursive: true);
      } on Object catch (error, stackTrace) {
        _logger.log(
          Level.warn,
          "Downloadディレクトリの作成に失敗",
          tag: "CsvExportFileSaver",
          error: error,
          st: stackTrace,
        );
        return null;
      }
    }
    return File("${downloads.path}/$fileName");
  }

  Future<CsvFileSaveSummary> _saveForDesktop(CsvExportResult result) async {
    final FileSaveLocation? location = await getSaveLocation(
      suggestedName: result.fileName,
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(
          label: "データエクスポート",
          extensions: <String>[result.fileName.split(".").last],
        ),
      ],
    );

    if (location == null) {
      return const CsvFileSaveSummary(saved: false);
    }

    final Uint8List data = Uint8List.fromList(result.bytes);
    final XFile exportFile = XFile.fromData(
      data,
      name: result.fileName,
      mimeType: result.contentType,
    );
    try {
      await exportFile.saveTo(location.path);
    } on Object catch (error, stackTrace) {
      _logger.e(
        "デスクトップへのファイル保存に失敗",
        tag: "CsvExportFileSaver",
        error: error,
        st: stackTrace,
      );
      throw CsvFileSaveException("ファイルの保存に失敗しました", cause: error);
    }

    return CsvFileSaveSummary(saved: true, path: location.path);
  }

  Future<CsvFileSaveSummary> _saveToTemporary(CsvExportResult result) async {
    final Directory directory = await getTemporaryDirectory();
    final File file = File("${directory.path}/${result.fileName}");
    try {
      await file.writeAsBytes(result.bytes, flush: true);
    } on Object catch (error, stackTrace) {
      _logger.e(
        "テンポラリへの保存に失敗",
        tag: "CsvExportFileSaver",
        error: error,
        st: stackTrace,
      );
      throw CsvFileSaveException("一時ディレクトリへの保存に失敗しました", cause: error);
    }

    return CsvFileSaveSummary(saved: true, path: file.path);
  }
}
