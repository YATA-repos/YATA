import "dart:async";
import "dart:collection";
import "dart:developer" as developer;
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:path_provider/path_provider.dart";

import "../constants/enums.dart";
import "../error/base.dart";

/// 統一ログサービス
///
/// 開発時は全レベルをconsoleに出力し、リリース時はwarning/errorのみをファイルに保存する
/// ビジネスロジック関連のログは英語・日本語併用可能
class LogService {
  // プライベートコンストラクタ
  LogService._();
  static LogService? _instance;
  static bool _initialized = false;
  static String? _logDirectory;
  static LogLevel _minimumLevel = LogLevel.debug;
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int _bufferSize = 100;
  static const int _flushInterval = 5; // seconds

  static final Queue<String> _logBuffer = Queue<String>();
  static Timer? _flushTimer;
  static bool _isFlushInProgress = false;

  /// シングルトンインスタンスを取得
  static LogService get instance {
    _instance ??= LogService._();
    return _instance!;
  }

  /// ログサービスの初期化
  ///
  /// アプリケーション起動時に一度だけ呼び出してください。
  ///
  /// [minimumLevel] 出力する最小ログレベル（デフォルト：debug）
  static Future<void> initialize({LogLevel? minimumLevel}) async {
    if (_initialized) return;

    try {
      // 最小ログレベルを設定
      if (minimumLevel != null) {
        _minimumLevel = minimumLevel;
      }

      // リリースビルドの場合はログディレクトリを設定
      if (kReleaseMode) {
        await _setupLogDirectory();
        // バッファフラッシュタイマーを開始
        _startFlushTimer();
      }

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

  /// 最小ログレベルを動的に変更
  static void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
    _log(
      LogLevel.info,
      "LogService",
      "Minimum log level changed to ${level.value}",
    );
  }

  /// バッファフラッシュタイマーを開始
  static void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(Duration(seconds: _flushInterval), (_) {
      flushBuffer();
    });
  }

  /// ログサービスの終了処理
  static Future<void> dispose() async {
    _flushTimer?.cancel();
    await flushBuffer();
    _initialized = false;
  }

  /// プラットフォーム別ログディレクトリを設定
  static Future<void> _setupLogDirectory() async {
    try {
      String? envPath;

      // プラットフォーム別環境変数から取得
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

      Directory logDir;

      if (envPath != null && envPath.isNotEmpty) {
        // 環境変数で指定されたパスを使用
        logDir = Directory(envPath);
      } else {
        // デフォルトのアプリケーションディレクトリを使用
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

  /// デバッグレベルログ（開発時のみ）
  static void debug(String component, String message, [String? messageJa]) {
    _log(LogLevel.debug, component, message, messageJa);
  }

  /// 情報レベルログ
  static void info(String component, String message, [String? messageJa]) {
    _log(LogLevel.info, component, message, messageJa);
  }

  /// 警告レベルログ（リリース時もファイル保存）
  static void warning(String component, String message, [String? messageJa]) {
    _log(LogLevel.warning, component, message, messageJa);
  }

  /// エラーレベルログ（リリース時もファイル保存）
  static void error(
    String component,
    String message, [
    String? messageJa,
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.error, component, message, messageJa, error, stackTrace);
  }

  // --- エラー定義を使った便利メソッド ---

  /// 情報レベルログ（事前定義メッセージ使用）
  static void infoWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    final String message = params != null
        ? logMessage.withParams(params)
        : logMessage.combinedMessage;
    _log(LogLevel.info, component, message);
  }

  /// 警告レベルログ（事前定義メッセージ使用）
  static void warningWithMessage(
    String component,
    LogMessage logMessage, [
    Map<String, String>? params,
  ]) {
    final String message = params != null
        ? logMessage.withParams(params)
        : logMessage.combinedMessage;
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
    final String message = params != null
        ? logMessage.withParams(params)
        : logMessage.combinedMessage;
    _log(LogLevel.error, component, message, null, error, stackTrace);
  }

  /// 内部ログ処理
  static void _log(
    LogLevel level,
    String component,
    String message, [
    String? messageJa,
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // 最小ログレベルチェック
    if (level.priority < _minimumLevel.priority) {
      return;
    }

    // メッセージフォーマット
    final String formattedMessage = _formatMessage(message, messageJa);
    final String timestamp = DateTime.now().toIso8601String();

    // 開発時は常にconsoleに出力
    if (kDebugMode) {
      developer.log(
        formattedMessage,
        time: DateTime.now(),
        level: level.developerLevel,
        name: component,
        error: error,
        stackTrace: stackTrace,
      );
    }

    // リリース時はwarning/errorのみファイル保存（バッファリング）
    if (kReleaseMode && level.shouldPersistInRelease && _logDirectory != null) {
      _addToBuffer(
        level,
        component,
        formattedMessage,
        timestamp,
        error,
        stackTrace,
      );
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
    final StringBuffer entry = StringBuffer();
    entry.writeln(
      "[$timestamp] [$component] [${level.value.toUpperCase()}] $message",
    );

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
      developer.log(
        "Failed to flush log buffer: ${e.toString()}",
        level: 900,
        name: "LogService",
      );
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

      // ファイルに追記（再試行ロジック付き）
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
  static Future<void> _writeWithRetry(
    File file,
    String content, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await file.writeAsString(content, mode: FileMode.append);
        return;
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
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
      developer.log(
        "Failed to rotate log file: ${e.toString()}",
        level: 900,
        name: "LogService",
      );
    }
  }

  /// メッセージフォーマット（英語・日本語併用対応）
  static String _formatMessage(String message, String? messageJa) {
    if (messageJa != null && messageJa.isNotEmpty) {
      return "$message ($messageJa)";
    }
    return message;
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

  /// ログファイルのクリーンアップ（古いファイルを削除）
  ///
  /// [daysToKeep] 保持する日数（デフォルト：30日）
  static Future<void> cleanupOldLogs({int daysToKeep = 30}) async {
    if (_logDirectory == null) return;

    try {
      final Directory logDir = Directory(_logDirectory!);
      if (!await logDir.exists()) return;

      final DateTime cutoffDate = DateTime.now().subtract(
        Duration(days: daysToKeep),
      );
      final List<FileSystemEntity> files = await logDir.list().toList();

      for (final FileSystemEntity file in files) {
        if (file is File && file.path.endsWith(".log")) {
          final FileStat stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            _log(
              LogLevel.info,
              "LogService",
              "Deleted old log file: ${file.path}",
            );
          }
        }
      }
    } catch (e) {
      _log(
        LogLevel.warning,
        "LogService",
        "Failed to cleanup old logs: ${e.toString()}",
      );
    }
  }
}
