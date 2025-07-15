import "dart:async";
import "dart:collection";
import "dart:developer" as developer;
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:path_provider/path_provider.dart";

import "../base/base_error_msg.dart";
import "../constants/enums.dart";

/// 統一ログサービス
///
/// 開発時は全レベルをconsoleに出力し、リリース時はwarning/errorのみをファイルに保存する
/// 全てのログメッセージは英語で記録される
class LogService {
  LogService._();
  static LogService? _instance;
  static bool _initialized = false;
  static String? _logDirectory;
  static LogLevel _minimumLevel = LogLevel.debug;
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int _bufferSize = 100;
  static const int _flushInterval = 5; // sec

  static final Queue<String> _logBuffer = Queue<String>();
  static Timer? _flushTimer;
  static bool _isFlushInProgress = false;

  /// シングルトン
  static LogService get instance {
    _instance ??= LogService._();
    return _instance!;
  }

  /// ログサービスを初期化する
  static Future<void> initialize({LogLevel? minimumLevel}) async {
    if (_initialized) {
      return;
    }

    try {
      if (minimumLevel != null) {
        _minimumLevel = minimumLevel;
      }

      // デバッグ時もリリース時もログディレクトリを設定
      await _setupLogDirectory();
      // バッファフラッシュ用のタイマーを開始
      _startFlushTimer();

      _initialized = true;
      _log(LogLevel.info, "LogService", "Log service initialized successfully");
    } catch (e) {
      developer.log(
        "Failed to initialize LogService: ${e.toString()}",
        level: 1000,
        name: "LogService",
      );
    }
  }

  // 最小ログレベルを動的に変更するためのメソッド
  static void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
    _log(LogLevel.info, "LogService", "Minimum log level changed to ${level.value}");
  }

  /// バッファフラッシュタイマーを開始する用のメソッド
  static void _startFlushTimer() {
    // 既存のタイマーがあればキャンセル
    _flushTimer?.cancel();
    // 新しいタイマーを開始
    _flushTimer = Timer.periodic(Duration(seconds: _flushInterval), (_) {
      flushBuffer();
    });
  }

  // ログサービスの終了処理
  static Future<void> dispose() async {
    _flushTimer?.cancel();
    await flushBuffer();
    _initialized = false;
  }

  // プラットフォーム別ログディレクトリを設定
  static Future<void> _setupLogDirectory() async {
    try {
      String? envPath;

      // デバッグ時とリリース時で異なる環境変数を使用
      if (kDebugMode) {
        envPath = dotenv.env["DEBUG_LOG_DIR"];
      } else {
        // リリース時はプラットフォーム別環境変数から取得
        if (Platform.isAndroid) {
          envPath = dotenv.env["LOG_PATH_ANDROID"];
        } else if (Platform.isIOS) {
          envPath = dotenv.env["LOG_PATH_IOS"];
        } else if (Platform.isWindows) {
          envPath = dotenv.env["LOG_PATH_WINDOWS"];
        } else if (Platform.isMacOS) {
          envPath = dotenv.env["LOG_PATH_MACOS"];
        } else if (Platform.isLinux) {
          envPath = dotenv.env["LOG_PATH_LINUX"];
        }
      }

      Directory logDir;

      if (envPath != null && envPath.isNotEmpty) {
        logDir = Directory(envPath);
      } else {
        // 環境変数から取得できない場合デフォルトを使用
        final Directory appDir = await getApplicationDocumentsDirectory();
        logDir = Directory("${appDir.path}/logs");
      }

      // ディレクトリが存在しない場合は作成
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logDirectory = logDir.path;
    } catch (e) {
      developer.log(
        "Failed to setup log directory: ${e.toString()}",
        level: 900,
        name: "LogService",
      );
      // ログディレクトリの設定に失敗してもアプリは継続
    }
  }

  /// デバッグレベルログ
  static void debug(String component, String message) {
    _log(LogLevel.debug, component, message);
  }

  /// 情報レベルログ
  static void info(String component, String message) {
    _log(LogLevel.info, component, message);
  }

  /// 警告レベルログ（リリース時もファイル保存）
  static void warning(String component, String message) {
    _log(LogLevel.warning, component, message);
  }

  /// エラーレベルログ（リリース時もファイル保存）
  static void error(String component, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, component, message, error, stackTrace);
  }

  // =================== ヘルパー ======================

  /// 情報レベルログ（事前定義メッセージ使用）
  static void infoWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    // 情報メッセージのパラメータが指定されている場合は置換
    final String message = params != null ? logMessage.withParams(params) : logMessage.message;
    _log(LogLevel.info, component, message);
  }

  /// 警告レベルログ（事前定義メッセージ使用）
  static void warningWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    // 警告メッセージのパラメータが指定されている場合は置換
    final String message = params != null ? logMessage.withParams(params) : logMessage.message;
    _log(LogLevel.warning, component, message);
  }

  /// エラーレベルログ（事前定義メッセージ使用）
  static void errorWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // エラーメッセージのパラメータが指定されている場合は置換
    final String message = params != null ? logMessage.withParams(params) : logMessage.message;
    _log(LogLevel.error, component, message, error, stackTrace);
  }

  /// 内部ログ処理
  static void _log(
    LogLevel level,
    String component,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // 最小ログレベルチェック
    if (level.priority < _minimumLevel.priority) {
      return;
    }

    final String timestamp = DateTime.now().toIso8601String();

    // 開発時は常にconsoleに出力
    if (kDebugMode) {
      developer.log(
        message,
        time: DateTime.now(),
        level: level.developerLevel,
        name: component,
        error: error,
        stackTrace: stackTrace,
      );
    }

    // デバッグ時は全レベル、リリース時はwarning/errorのみファイル保存(バッファ)
    if (_logDirectory != null) {
      if (kDebugMode || (kReleaseMode && level.shouldPersistInRelease)) {
        _addToBuffer(level, component, message, timestamp, error, stackTrace);
      }
    }
  }

  /// ログをバッファに追加
  static void _addToBuffer(
    LogLevel level,
    String component,
    String message,
    String timestamp,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final String logEntry = _formatLogEntry(
      level,
      component,
      message,
      timestamp,
      error,
      stackTrace,
    );

    _logBuffer.add(logEntry);

    // バッファサイズを超えた場合は古いエントリを削除
    while (_logBuffer.length > _bufferSize) {
      _logBuffer.removeFirst();
    }

    // エラーレベルの場合は即座にフラッシュ
    if (level == LogLevel.error) {
      flushBuffer();
    }
  }

  /// ログエントリをフォーマット
  static String _formatLogEntry(
    LogLevel level,
    String component,
    String message,
    String timestamp,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final StringBuffer entry = StringBuffer()
      ..writeln("[$timestamp] [$component] [${level.value.toUpperCase()}] $message");

    if (error != null) {
      entry.writeln("Error: $error");
    }

    if (stackTrace != null) {
      entry.writeln("StackTrace: $stackTrace");
    }

    entry.writeln("---");
    return entry.toString();
  }

  /// バッファの内容をファイルに書き込み
  static Future<void> flushBuffer() async {
    if (_isFlushInProgress || _logBuffer.isEmpty || _logDirectory == null) {
      return;
    }

    _isFlushInProgress = true;

    try {
      final List<String> entries = List<String>.from(_logBuffer);
      _logBuffer.clear();

      for (final String entry in entries) {
        await _writeBufferedEntry(entry);
      }
    } catch (e) {
      developer.log("Failed to flush log buffer: ${e.toString()}", level: 900, name: "LogService");
    } finally {
      _isFlushInProgress = false;
    }
  }

  /// バッファされたエントリをファイルに書き込み
  static Future<void> _writeBufferedEntry(String entry) async {
    try {
      final DateTime today = DateTime.now();
      final String dateStr =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';

      final String filename = "$dateStr-mixed.log";
      final File file = File("$_logDirectory/$filename");

      // ファイルサイズチェックとローテーション
      if (await file.exists()) {
        final FileStat stat = await file.stat();
        if (stat.size >= _maxFileSize) {
          await _rotateLogFile(file, dateStr);
        }
      }

      // ファイルに追記
      await _writeWithRetry(file, entry);
    } catch (e) {
      developer.log(
        "Failed to write buffered entry: ${e.toString()}",
        level: 900,
        name: "LogService",
      );
    }
  }

  /// 再試行付きファイル書き込み
  static Future<void> _writeWithRetry(File file, String content, {int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await file.writeAsString(content, mode: FileMode.append);
        return;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 100 * (attempt + 1)));
      }
    }
  }

  /// ログファイルのローテーション
  static Future<void> _rotateLogFile(File file, String dateStr) async {
    try {
      int rotationIndex = 1;
      String rotatedFilename;

      do {
        rotatedFilename = "$_logDirectory/$dateStr-mixed.$rotationIndex.log";
        rotationIndex++;
      } while (await File(rotatedFilename).exists());

      await file.rename(rotatedFilename);
    } catch (e) {
      developer.log("Failed to rotate log file: ${e.toString()}", level: 900, name: "LogService");
    }
  }

  /// ログファイル統計情報を取得
  static Future<Map<String, dynamic>> getLogStats() async {
    if (_logDirectory == null) {
      return <String, dynamic>{"error": "Log directory not initialized"};
    }

    try {
      final Directory logDir = Directory(_logDirectory!);
      if (!await logDir.exists()) {
        return <String, dynamic>{"error": "Log directory does not exist"};
      }

      final List<FileSystemEntity> files = await logDir
          .list()
          .where((FileSystemEntity f) => f.path.endsWith(".log"))
          .toList();
      final int totalFiles = files.length;
      int totalSize = 0;

      for (final FileSystemEntity file in files) {
        if (file is File) {
          final FileStat stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return <String, dynamic>{
        "totalFiles": totalFiles,
        "totalSizeBytes": totalSize,
        "totalSizeMB": (totalSize / (1024 * 1024)).toStringAsFixed(2),
        "bufferLength": _logBuffer.length,
        "minimumLevel": _minimumLevel.value,
        "flushInterval": _flushInterval,
      };
    } catch (e) {
      return <String, dynamic>{"error": e.toString()};
    }
  }

  /// 古いログファイルをクリーンアップする
  static Future<void> cleanupOldLogs({int daysToKeep = 30}) async {
    if (_logDirectory == null) {
      return;
    }

    try {
      final Directory logDir = Directory(_logDirectory!);
      if (!await logDir.exists()) {
        return;
      }

      // 切り捨て日を計算
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      // ディレクトリ内のログファイルを取得
      final List<FileSystemEntity> files = await logDir.list().toList();

      // 古いログファイルを削除
      for (final FileSystemEntity file in files) {
        if (file is File && file.path.endsWith(".log")) {
          final FileStat stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            _log(LogLevel.info, "LogService", "Deleted old log file: ${file.path}");
          }
        }
      }
    } catch (e) {
      _log(LogLevel.warning, "LogService", "Failed to cleanup old logs: ${e.toString()}");
    }
  }
}
