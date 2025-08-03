import "dart:async";
import "dart:collection";
import "dart:developer" as developer;
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:logger/logger.dart";
import "package:path_provider/path_provider.dart";

import "../constants/enums.dart";
import "logger_configuration.dart";

/// ログ装飾レベルの列挙型
enum LogDecorationLevel {
  /// 装飾なし（プレーンテキスト）
  none,
  /// 最小限の装飾（色分けのみ）
  minimal,
  /// 完全な装飾（色分け + アイコン + ハイライト）
  full,
}

/// ログ装飾用の定数とヘルパークラス
class LogDecorationConstants {
  /// ANSI色コード
  static const String reset = "\x1B[0m";
  static const String red = "\x1B[31m";
  static const String yellow = "\x1B[33m";
  static const String blue = "\x1B[34m";
  static const String gray = "\x1B[90m";
  static const String green = "\x1B[32m";
  static const String cyan = "\x1B[36m";
  static const String magenta = "\x1B[35m";
  
  /// 背景色（ハイライト用）
  static const String redBg = "\x1B[41m";
  static const String yellowBg = "\x1B[43m";
  
  /// スタイル
  static const String bold = "\x1B[1m";
  static const String underline = "\x1B[4m";
  
  /// アイコン定数
  static const String errorIcon = "🔴";
  static const String warningIcon = "⚠️";
  static const String infoIcon = "ℹ️";
  static const String debugIcon = "🔍";
  static const String fatalIcon = "💥";
  static const String traceIcon = "🔎";
  
  /// ハイライト用文字（枠線作成用）
  static const String boxTop = "╔";
  static const String boxBottom = "╚";
  static const String boxSide = "║";
  static const String boxHorizontal = "═";
  static const String boxTopRight = "╗";
  static const String boxBottomRight = "╝";
  
  /// ログレベル別色分けマッピング
  static String getColorForLevel(Level level) {
    switch (level) {
      case Level.trace:
        return gray;
      case Level.debug:
        return gray;
      case Level.info:
        return blue;
      case Level.warning:
        return yellow;
      case Level.error:
        return red;
      case Level.fatal:
        return "$bold$red";
      case Level.all:
      case Level.off:
      default:
        return reset;
    }
  }
  
  /// ログレベル別アイコンマッピング
  static String getIconForLevel(Level level) {
    switch (level) {
      case Level.trace:
        return traceIcon;
      case Level.debug:
        return debugIcon;
      case Level.trace:
        return debugIcon;
      case Level.info:
        return infoIcon;
      case Level.warning:
        return warningIcon;
      case Level.error:
        return errorIcon;
      case Level.fatal:
        return fatalIcon;
      case Level.all:
      case Level.off:
      default:
        return "";
    }
  }
  
  /// コンポーネント名用の色（ハッシュベース）
  static String getComponentColor(String component) {
    final int hash = component.hashCode;
    const List<String> colors = <String>[cyan, green, magenta, blue, yellow];
    return colors[hash.abs() % colors.length];
  }
}

/// 統一YATA専用LogFilter (logger パッケージ完全準拠)
/// 
/// 既存の2つのYataLogFilter実装を統合・最適化
/// LogLevelを使用したフィルタリングと動的レベル変更機能を提供
/// logger パッケージのLogFilterアーキテクチャを完全活用
class UnifiedYataLogFilter extends LogFilter {
  
  UnifiedYataLogFilter(this._minimumLevel);
  LogLevel _minimumLevel;

  @override
  bool shouldLog(LogEvent event) {
    final LogLevel yataLevel = _mapLoggerLevelToYataLevel(event.level);
    return yataLevel.priority >= _minimumLevel.priority;
  }

  /// 動的にレベル変更
  /// 
  /// [level] 新しい最小ログレベル
  void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
  }

  /// 現在の最小レベルを取得
  LogLevel get minimumLevel => _minimumLevel;

  /// logger.LevelからYATA LogLevelへのマッピング
  /// 
  /// logger パッケージの標準レベルをYATAのLogLevelに対応
  LogLevel _mapLoggerLevelToYataLevel(Level loggerLevel) {
    switch (loggerLevel) {
      case Level.trace:
      case Level.debug:
      case Level.trace:
        return LogLevel.debug;
      case Level.info:
        return LogLevel.info;
      case Level.warning:
        return LogLevel.warning;
      case Level.error:
      case Level.fatal:
      case Level.fatal:
        return LogLevel.error;
      case Level.all:
      case Level.off:
      case Level.off:
      default:
        return LogLevel.debug;
    }
  }

  /// YATA LogLevelからlogger.Levelへのマッピング
  /// 
  /// YATAのLogLevelをlogger パッケージの標準レベルに変換
  static Level mapYataLevelToLoggerLevel(LogLevel yataLevel) {
    switch (yataLevel) {
      case LogLevel.debug:
        return Level.debug;
      case LogLevel.info:
        return Level.info;
      case LogLevel.warning:
        return Level.warning;
      case LogLevel.error:
        return Level.error;
    }
  }

  /// logger パッケージの全レベルサポート確認
  /// 
  /// logger パッケージでサポートされているレベルをすべて適切にマッピング
  bool supportsLevel(Level loggerLevel) {
    switch (loggerLevel) {
      case Level.trace:
      case Level.debug:
      case Level.info:
      case Level.warning:
      case Level.error:
      case Level.fatal:
        return true;
      case Level.all:
      case Level.off:
      default:
        return false;
    }
  }

  /// フィルターの詳細情報を取得（デバッグ用）
  Map<String, dynamic> getFilterInfo() => <String, dynamic>{
      "minimumLevel": _minimumLevel.value,
      "minimumPriority": _minimumLevel.priority,
      "supportedLevels": Level.values.map((Level level) => level.name).toList(),
    };
}

/// 統一YATA専用LogPrinter (logger パッケージ完全準拠)
/// 
/// 既存の2つのYataLogPrinter実装を統合・最適化
/// YATAの統一ログフォーマットを維持しつつ、logger パッケージの機能を最大活用
/// 統一された見やすいログフォーマットを提供
class UnifiedYataLogPrinter extends LogPrinter {

  UnifiedYataLogPrinter({
    bool showTimestamp = false,
    bool showLevel = true,
    bool showComponent = true,
    int maxStackLines = 3,
    LogDecorationLevel decorationLevel = LogDecorationLevel.full,
    bool enableColorOutput = true,
    bool enableIcons = true,
    bool enableHighlight = true,
    bool enableComponentColors = true,
  })  : _showTimestamp = showTimestamp,
        _showLevel = showLevel,
        _showComponent = showComponent,
        _maxStackLines = maxStackLines,
        _decorationLevel = decorationLevel,
        _enableColorOutput = enableColorOutput,
        _enableIcons = enableIcons,
        _enableHighlight = enableHighlight,
        _enableComponentColors = enableComponentColors;

  /// 設定付きファクトリーコンストラクタ（開発用）
  factory UnifiedYataLogPrinter.development() => UnifiedYataLogPrinter(
      showTimestamp: true,
      maxStackLines: 5,
    );

  /// 設定付きファクトリーコンストラクタ（本番用）
  factory UnifiedYataLogPrinter.production() => UnifiedYataLogPrinter(
      maxStackLines: 2,
      decorationLevel: LogDecorationLevel.minimal,
      enableColorOutput: false,
      enableIcons: false,
      enableHighlight: false,
      enableComponentColors: false,
    );

  /// 最小限の装飾設定用ファクトリー
  factory UnifiedYataLogPrinter.minimal() => UnifiedYataLogPrinter(
      decorationLevel: LogDecorationLevel.minimal,
      enableIcons: false,
      enableHighlight: false,
      enableComponentColors: false,
    );

  /// 装飾なし設定用ファクトリー
  factory UnifiedYataLogPrinter.plain() => UnifiedYataLogPrinter(
      decorationLevel: LogDecorationLevel.none,
      enableColorOutput: false,
      enableIcons: false,
      enableHighlight: false,
      enableComponentColors: false,
    );
  final bool _showTimestamp;
  final bool _showLevel;
  final bool _showComponent;
  final int _maxStackLines;
  final LogDecorationLevel _decorationLevel;
  final bool _enableColorOutput;
  final bool _enableIcons;
  final bool _enableHighlight;
  final bool _enableComponentColors;

  @override
  List<String> log(LogEvent event) {
    final String message = event.message.toString();
    final String levelStr = event.level.name.toUpperCase();
    
    // メッセージからコンポーネント名を抽出
    String component = "Unknown";
    String actualMessage = message;
    
    // [Component] の形式でコンポーネントが含まれているかチェック
    if (message.startsWith("[") && message.contains("]")) {
      final int endBracket = message.indexOf("]");
      if (endBracket > 1) {
        component = message.substring(1, endBracket);
        actualMessage = message.substring(endBracket + 1).trim();
      }
    }
    
    final List<String> lines = <String>[];
    
    // メインメッセージの構築
    final String mainMessage = _buildMainMessage(
      component: component,
      level: levelStr,
      message: actualMessage,
      timestamp: event.time,
      logLevel: event.level,
    );
    
    // 重要ログの場合はハイライト枠線を適用
    final List<String> decoratedMainMessage = _createHighlightBox(mainMessage, event.level);
    lines.addAll(decoratedMainMessage);
    
    // エラー情報がある場合は追加（logger パッケージの機能活用）
    if (event.error != null) {
      final String errorMessage = _buildErrorMessage(
        component: component,
        level: levelStr,
        error: event.error!,
        logLevel: event.level,
      );
      lines.add(errorMessage);
    }
    
    // スタックトレースがある場合は追加（制限付き）
    if (event.stackTrace != null) {
      final List<String> stackMessages = _buildStackTraceMessages(
        component: component,
        level: levelStr,
        stackTrace: event.stackTrace!,
        logLevel: event.level,
      );
      lines.addAll(stackMessages);
    }
    
    return lines;
  }

  /// 装飾が有効かどうかを判定
  bool get _isDecorationEnabled => _decorationLevel != LogDecorationLevel.none;

  /// 色出力が有効かどうかを判定
  bool get _shouldUseColors => _isDecorationEnabled && _enableColorOutput;

  /// アイコンが有効かどうかを判定
  bool get _shouldUseIcons => _isDecorationEnabled && _enableIcons;

  /// ハイライトが有効かどうかを判定
  bool get _shouldUseHighlight => _isDecorationEnabled && _enableHighlight;

  /// コンポーネント色分けが有効かどうかを判定
  bool get _shouldUseComponentColors => _isDecorationEnabled && _enableComponentColors;

  /// ログレベルが重要（ERROR/FATAL）かどうかを判定
  bool _isCriticalLevel(Level level) => level == Level.error || level == Level.fatal;

  /// テキストに色を適用
  String _applyColor(String text, String color) {
    if (!_shouldUseColors) return text;
    return "$color$text${LogDecorationConstants.reset}";
  }

  /// アイコンを取得
  String _getIcon(Level level) {
    if (!_shouldUseIcons) return "";
    return LogDecorationConstants.getIconForLevel(level);
  }

  /// コンポーネント名に色を適用
  String _decorateComponent(String component) {
    if (!_shouldUseComponentColors) return component;
    final String color = LogDecorationConstants.getComponentColor(component);
    return _applyColor(component, color);
  }

  /// 重要ログのハイライト枠線を作成
  List<String> _createHighlightBox(String content, Level level) {
    if (!_shouldUseHighlight || !_isCriticalLevel(level)) {
      return <String>[content];
    }

    final int contentLength = content.length;
    final String color = LogDecorationConstants.getColorForLevel(level);
    final String topLine = _applyColor(
      "${LogDecorationConstants.boxTop}${LogDecorationConstants.boxHorizontal * (contentLength + 2)}${LogDecorationConstants.boxTopRight}",
      color,
    );
    final String middleLine = _applyColor(
      "${LogDecorationConstants.boxSide} $content ${LogDecorationConstants.boxSide}",
      color,
    );
    final String bottomLine = _applyColor(
      "${LogDecorationConstants.boxBottom}${LogDecorationConstants.boxHorizontal * (contentLength + 2)}${LogDecorationConstants.boxBottomRight}",
      color,
    );

    return <String>[topLine, middleLine, bottomLine];
  }

  /// メインメッセージの構築
  String _buildMainMessage({
    required String component,
    required String level,
    required String message,
    required DateTime timestamp,
    required Level logLevel,
  }) {
    final List<String> parts = <String>[];
    
    // アイコン（装飾機能有効時）
    final String icon = _getIcon(logLevel);
    if (icon.isNotEmpty) {
      parts.add(icon);
    }
    
    // タイムスタンプ（オプション）
    if (_showTimestamp) {
      final String timeStr = _formatTimestamp(timestamp);
      parts.add(timeStr);
    }
    
    // コンポーネント（オプション）
    if (_showComponent) {
      final String decoratedComponent = _decorateComponent(component);
      parts.add("[$decoratedComponent]");
    }
    
    // レベル（オプション）
    if (_showLevel) {
      final String coloredLevel = _applyColor("[$level]", LogDecorationConstants.getColorForLevel(logLevel));
      parts.add(coloredLevel);
    }
    
    // メッセージ（色付き）
    final String coloredMessage = _applyColor(message, LogDecorationConstants.getColorForLevel(logLevel));
    parts.add(coloredMessage);
    
    return parts.join(" ");
  }

  /// エラーメッセージの構築
  String _buildErrorMessage({
    required String component,
    required String level,
    required Object error,
    required Level logLevel,
  }) {
    final List<String> parts = <String>[];
    
    // アイコン（装飾機能有効時）
    final String icon = _getIcon(logLevel);
    if (icon.isNotEmpty) {
      parts.add(icon);
    }
    
    if (_showComponent) {
      final String decoratedComponent = _decorateComponent(component);
      parts.add("[$decoratedComponent]");
    }
    
    if (_showLevel) {
      final String coloredLevel = _applyColor("[$level]", LogDecorationConstants.getColorForLevel(logLevel));
      parts.add(coloredLevel);
    }
    
    final String errorText = "Error: ${error.toString()}";
    final String coloredError = _applyColor(errorText, LogDecorationConstants.getColorForLevel(logLevel));
    parts.add(coloredError);
    
    return parts.join(" ");
  }

  /// スタックトレースメッセージの構築
  List<String> _buildStackTraceMessages({
    required String component,
    required String level,
    required StackTrace stackTrace,
    required Level logLevel,
  }) {
    final List<String> stackLines = stackTrace.toString().split("\n");
    final List<String> result = <String>[];
    
    // 制限された行数のみ表示
    final List<String> limitedStack = stackLines.take(_maxStackLines).toList();
    
    for (int i = 0; i < limitedStack.length; i++) {
      final String stackLine = limitedStack[i].trim();
      if (stackLine.isNotEmpty) {
        final List<String> parts = <String>[];
        
        // アイコン（装飾機能有効時）
        final String icon = _getIcon(logLevel);
        if (icon.isNotEmpty) {
          parts.add(icon);
        }
        
        if (_showComponent) {
          final String decoratedComponent = _decorateComponent(component);
          parts.add("[$decoratedComponent]");
        }
        
        if (_showLevel) {
          final String coloredLevel = _applyColor("[$level]", LogDecorationConstants.getColorForLevel(logLevel));
          parts.add(coloredLevel);
        }
        
        final String stackText = "Stack[$i]: $stackLine";
        final String coloredStack = _applyColor(stackText, LogDecorationConstants.getColorForLevel(logLevel));
        parts.add(coloredStack);
        result.add(parts.join(" "));
      }
    }
    
    return result;
  }

  /// タイムスタンプフォーマット
  String _formatTimestamp(DateTime timestamp) => "${timestamp.hour.toString().padLeft(2, '0')}:"
           "${timestamp.minute.toString().padLeft(2, '0')}:"
           "${timestamp.second.toString().padLeft(2, '0')}.";

  /// プリンターの設定情報を取得（デバッグ用）
  Map<String, dynamic> getPrinterInfo() => <String, dynamic>{
      "showTimestamp": _showTimestamp,
      "showLevel": _showLevel,
      "showComponent": _showComponent,
      "maxStackLines": _maxStackLines,
      "decorationLevel": _decorationLevel.name,
      "enableColorOutput": _enableColorOutput,
      "enableIcons": _enableIcons,
      "enableHighlight": _enableHighlight,
      "enableComponentColors": _enableComponentColors,
      "isDecorationEnabled": _isDecorationEnabled,
    };
}

/// 統一バッファリング機能付きファイルLogOutput (logger パッケージ完全準拠)
/// 
/// 既存の2つのBufferedFileOutput実装を統合・最適化
/// logger パッケージのLogOutputアーキテクチャを完全活用
/// 高性能バッファリング・ファイル管理機能を提供
class UnifiedBufferedFileOutput extends LogOutput {

  /// デフォルトコンストラクタ
  UnifiedBufferedFileOutput({
    int maxFileSize = 10 * 1024 * 1024, // 10MB
    int bufferSize = 100,
    int flushInterval = 5, // seconds
    bool immediateFlushOnError = true,
    int maxFileRetention = 30, // days
  })  : _maxFileSize = maxFileSize,
        _bufferSize = bufferSize,
        _flushInterval = flushInterval,
        _immediateFlushOnError = immediateFlushOnError,
        _maxFileRetention = maxFileRetention;

  /// LoggerConfigから設定を読み込むファクトリーコンストラクタ
  factory UnifiedBufferedFileOutput.fromConfig() => UnifiedBufferedFileOutput(
      maxFileSize: LoggerConfig.maxFileSizeBytes,
      bufferSize: LoggerConfig.bufferSize,
      flushInterval: LoggerConfig.flushIntervalSeconds,
      maxFileRetention: LoggerConfig.defaultCleanupDays,
    );
  // 設定可能パラメータ
  late final int _maxFileSize;
  late final int _bufferSize;
  late final int _flushInterval;
  late final bool _immediateFlushOnError;
  late final int _maxFileRetention;

  String? _logDirectory;
  final Queue<String> _logBuffer = Queue<String>();
  Timer? _flushTimer;
  bool _isFlushInProgress = false;
  bool _initialized = false;
  int _currentFileSize = 0;
  String? _currentLogFileName;

  /// 初期化処理
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await _setupLogDirectory();
      await _initializeCurrentLogFile();
      _startFlushTimer();
      _initialized = true;
      
      developer.log(
        "UnifiedBufferedFileOutput initialized successfully",
        name: "UnifiedBufferedFileOutput",
      );
    } catch (e, stackTrace) {
      developer.log(
        "Failed to initialize UnifiedBufferedFileOutput: ${e.toString()}",
        level: 1000,
        name: "UnifiedBufferedFileOutput",
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  void output(OutputEvent event) {
    if (!_initialized || _logDirectory == null) {
      // 初期化されていない場合はConsoleOutputにフォールバック
      _fallbackOutput(event);
      return;
    }

    final String logEntry = _formatLogEntry(event);
    _addToBuffer(logEntry);
    
    // エラーレベル・ファタルレベルの場合は即座にフラッシュ
    if (_immediateFlushOnError && 
        (event.level == Level.error || event.level == Level.fatal)) {
      _flushBuffer();
    }
  }

  /// フォールバック出力
  void _fallbackOutput(OutputEvent event) {
    for (final String line in event.lines) {
      developer.log(line, name: "FallbackOutput");
    }
  }

  /// ログエントリをフォーマット（logger パッケージのOutputEventを活用）
  String _formatLogEntry(OutputEvent event) {
    final StringBuffer entry = StringBuffer();
    final DateTime now = DateTime.now();
    final String timestamp = now.toIso8601String();
    final String levelStr = event.level.name.toUpperCase();
    
    for (final String line in event.lines) {
      entry.writeln("[$timestamp] [$levelStr] $line");
    }
    
    return entry.toString();
  }

  /// バッファにログエントリを追加
  void _addToBuffer(String logEntry) {
    _logBuffer.add(logEntry);
    
    // バッファサイズを超えた場合は古いエントリを削除
    while (_logBuffer.length > _bufferSize) {
      _logBuffer.removeFirst();
    }
    
    // バッファが満杯になった場合は自動フラッシュ
    if (_logBuffer.length >= _bufferSize) {
      _flushBuffer();
    }
  }

  /// プラットフォーム別ログディレクトリを設定
  Future<void> _setupLogDirectory() async {
    try {
      String? envPath;

      // デバッグ時とリリース時で異なる環境変数を使用
      if (kDebugMode) {
        envPath = dotenv.env["DEBUG_LOG_DIR"];
      } else {
        envPath = dotenv.env["RELEASE_LOG_DIR"];
      }

      Directory logDir;
      
      if (envPath != null && envPath.isNotEmpty) {
        // 環境変数で指定されたパスを使用
        logDir = Directory(envPath);
      } else {
        // プラットフォーム別のデフォルトパス
        if (Platform.isAndroid || Platform.isIOS) {
          final Directory appDir = await getApplicationDocumentsDirectory();
          logDir = Directory("${appDir.path}/logs");
        } else if (Platform.isWindows) {
          final Directory appDir = await getApplicationDocumentsDirectory();
          logDir = Directory("${appDir.path}\\logs");
        } else if (Platform.isLinux || Platform.isMacOS) {
          final Directory appDir = await getApplicationDocumentsDirectory();
          logDir = Directory("${appDir.path}/logs");
        } else {
          // フォールバック: カレントディレクトリ
          logDir = Directory("./logs");
        }
      }

      // ディレクトリが存在しない場合は作成
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logDirectory = logDir.path;
    } catch (e) {
      developer.log(
        "Failed to setup log directory: ${e.toString()}",
        name: "UnifiedBufferedFileOutput",
        error: e,
      );
      rethrow;
    }
  }

  /// 現在のログファイルを初期化
  Future<void> _initializeCurrentLogFile() async {
    if (_logDirectory == null) return;
    
    final DateTime now = DateTime.now();
    final String dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _currentLogFileName = "yata_log_$dateStr.log";
    
    final String filePath = "$_logDirectory/$_currentLogFileName";
    final File file = File(filePath);
    
    if (await file.exists()) {
      final FileStat stat = await file.stat();
      _currentFileSize = stat.size;
    } else {
      _currentFileSize = 0;
    }
  }

  /// フラッシュタイマーを開始
  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      Duration(seconds: _flushInterval),
      (Timer timer) => _flushBuffer(),
    );
  }

  /// バッファの内容をファイルに書き込み
  Future<void> _flushBuffer() async {
    if (_isFlushInProgress || 
        _logBuffer.isEmpty || 
        _logDirectory == null ||
        _currentLogFileName == null) {
      return;
    }

    _isFlushInProgress = true;

    try {
      final String filePath = "$_logDirectory/$_currentLogFileName";
      final File file = File(filePath);
      
      // ファイルサイズチェック・ローテーション
      await _checkAndRotateFile(file);
      
      // バッファの内容を書き込み
      final List<String> bufferContent = _logBuffer.toList();
      _logBuffer.clear();
      
      final String content = bufferContent.join();
      await file.writeAsString(content, mode: FileMode.append);
      
      _currentFileSize += content.length;
      
    } catch (e, stackTrace) {
      developer.log(
        "Failed to flush buffer to file",
        name: "UnifiedBufferedFileOutput",
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isFlushInProgress = false;
    }
  }

  /// ファイルサイズチェック・ローテーション
  Future<void> _checkAndRotateFile(File file) async {
    if (_currentFileSize >= _maxFileSize) {
      await _rotateLogFile();
    }
  }

  /// ログファイルローテーション
  Future<void> _rotateLogFile() async {
    if (_logDirectory == null || _currentLogFileName == null) return;
    
    try {
      final String currentPath = "$_logDirectory/$_currentLogFileName";
      final File currentFile = File(currentPath);
      
      if (await currentFile.exists()) {
        final DateTime now = DateTime.now();
        final String timestamp = "${now.hour.toString().padLeft(2, '0')}"
                                "${now.minute.toString().padLeft(2, '0')}"
                                "${now.second.toString().padLeft(2, '0')}";
        
        final String rotatedName = "$_currentLogFileName.$timestamp";
        final String rotatedPath = "$_logDirectory/$rotatedName";
        
        await currentFile.rename(rotatedPath);
      }
      
      await _initializeCurrentLogFile();
      
    } catch (e) {
      developer.log(
        "Failed to rotate log file",
        name: "UnifiedBufferedFileOutput",
        error: e,
      );
    }
  }

  /// 古いログファイルをクリーンアップ
  /// 
  /// [daysToKeep] 保持する日数（デフォルトは設定値）
  /// [dryRun] trueの場合、削除対象を特定するのみで実際の削除は行わない
  /// [maxFilesToDelete] 一度に削除するファイル数の上限（安全性のため）
  /// 戻り値: クリーンアップ統計情報
  Future<Map<String, dynamic>> cleanupOldLogs({
    int? daysToKeep,
    bool dryRun = false,
    int maxFilesToDelete = 100,
  }) async {
    final int retentionDays = daysToKeep ?? _maxFileRetention;
    final DateTime startTime = DateTime.now();
    
    final Map<String, dynamic> cleanupStats = <String, dynamic>{
      "retentionDays": retentionDays,
      "dryRun": dryRun,
      "startTime": startTime.toIso8601String(),
      "filesScanned": 0,
      "filesDeleted": 0,
      "totalSizeDeleted": 0,
      "errors": <String>[],
      "deletedFiles": <String>[],
    };
    
    if (_logDirectory == null) {
      cleanupStats["error"] = "Log directory not initialized";
      return cleanupStats;
    }
    
    try {
      final Directory logDir = Directory(_logDirectory!);
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      
      final List<File> filesToDelete = <File>[];
      int totalSizeToDelete = 0;
      
      // 第1段階: 削除対象ファイルを特定
      await for (final FileSystemEntity entity in logDir.list()) {
        if (entity is File && entity.path.endsWith(".log")) {
          cleanupStats["filesScanned"] = (cleanupStats["filesScanned"] as int) + 1;
          
          try {
            final FileStat stat = await entity.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              filesToDelete.add(entity);
              totalSizeToDelete += stat.size;
              
              // 安全性のため削除ファイル数を制限
              if (filesToDelete.length >= maxFilesToDelete) {
                developer.log(
                  "Cleanup file limit reached: $maxFilesToDelete files",
                  name: "UnifiedBufferedFileOutput",
                );
                break;
              }
            }
          } catch (e) {
            final String error = "Failed to stat file ${entity.path}: ${e.toString()}";
            (cleanupStats["errors"] as List<String>).add(error);
          }
        }
      }
      
      cleanupStats["totalSizeToDelete"] = totalSizeToDelete;
      
      // 第2段階: 実際の削除実行（dryRunでない場合）
      if (!dryRun && filesToDelete.isNotEmpty) {
        for (final File file in filesToDelete) {
          try {
            final String fileName = file.path.split("/").last;
            final int fileSize = await file.length();
            
            await file.delete();
            
            cleanupStats["filesDeleted"] = (cleanupStats["filesDeleted"] as int) + 1;
            cleanupStats["totalSizeDeleted"] = (cleanupStats["totalSizeDeleted"] as int) + fileSize;
            (cleanupStats["deletedFiles"] as List<String>).add(fileName);
            
            developer.log(
              "Deleted old log file: $fileName (${(fileSize / 1024).toStringAsFixed(1)} KB)",
              name: "UnifiedBufferedFileOutput",
            );
          } catch (e) {
            final String error = "Failed to delete file ${file.path}: ${e.toString()}";
            (cleanupStats["errors"] as List<String>).add(error);
          }
        }
      } else if (dryRun && filesToDelete.isNotEmpty) {
        // ドライランの場合は削除予定ファイルをログに記録
        for (final File file in filesToDelete) {
          final String fileName = file.path.split("/").last;
          (cleanupStats["deletedFiles"] as List<String>).add("$fileName (dry-run)");
        }
        developer.log(
          "Dry run: Would delete ${filesToDelete.length} files (${(totalSizeToDelete / 1024).toStringAsFixed(1)} KB)",
          name: "UnifiedBufferedFileOutput",
        );
      }
      
      final Duration elapsed = DateTime.now().difference(startTime);
      cleanupStats["duration"] = elapsed.inMilliseconds;
      cleanupStats["completed"] = true;
      
      // 結果のサマリーログ
      if (!dryRun) {
        developer.log(
          "Log cleanup completed: ${cleanupStats['filesDeleted']} files deleted, "
          "${((cleanupStats['totalSizeDeleted'] as int) / 1024).toStringAsFixed(1)} KB freed in ${elapsed.inMilliseconds}ms",
          name: "UnifiedBufferedFileOutput",
        );
      }
      
    } catch (e) {
      final String error = "Log cleanup failed: ${e.toString()}";
      cleanupStats["error"] = error;
      cleanupStats["completed"] = false;
      developer.log(error, name: "UnifiedBufferedFileOutput", error: e);
    }
    
    return cleanupStats;
  }

  /// ログ統計情報を取得
  Future<Map<String, dynamic>> getLogStats() async {
    final Map<String, dynamic> stats = <String, dynamic>{
      "initialized": _initialized,
      "logDirectory": _logDirectory,
      "currentLogFile": _currentLogFileName,
      "currentFileSize": _currentFileSize,
      "bufferSize": _logBuffer.length,
      "maxBufferSize": _bufferSize,
      "maxFileSize": _maxFileSize,
      "flushInterval": _flushInterval,
      "isFlushInProgress": _isFlushInProgress,
    };

    if (_logDirectory != null) {
      try {
        final Directory logDir = Directory(_logDirectory!);
        final List<FileSystemEntity> logFiles = await logDir
            .list()
            .where((FileSystemEntity entity) => entity is File && entity.path.endsWith(".log"))
            .toList();
        
        stats["totalLogFiles"] = logFiles.length;
        
        int totalSize = 0;
        for (final FileSystemEntity file in logFiles) {
          final FileStat stat = await file.stat();
          totalSize += stat.size;
        }
        stats["totalLogSize"] = totalSize;
      } catch (e) {
        stats["error"] = "Failed to get directory stats: ${e.toString()}";
      }
    }

    return stats;
  }

  /// バッファの内容を強制的にファイルに書き込み
  Future<void> flushBuffer() async {
    if (!_initialized || _isFlushInProgress) return;
    await _flushBuffer();
  }

  /// リソースの解放
  Future<void> dispose() async {
    if (!_initialized) return;
    
    // 最終フラッシュ
    await _flushBuffer();
    
    // タイマー停止
    _flushTimer?.cancel();
    _flushTimer = null;
    
    // バッファクリア
    _logBuffer.clear();
    
    _initialized = false;
    _logDirectory = null;
    _currentLogFileName = null;
    _currentFileSize = 0;
  }

  /// 出力の設定情報を取得（デバッグ用）
  Map<String, dynamic> getOutputInfo() => <String, dynamic>{
      "maxFileSize": _maxFileSize,
      "bufferSize": _bufferSize,
      "flushInterval": _flushInterval,
      "immediateFlushOnError": _immediateFlushOnError,
      "maxFileRetention": _maxFileRetention,
      "initialized": _initialized,
      "currentBufferLength": _logBuffer.length,
    };
}