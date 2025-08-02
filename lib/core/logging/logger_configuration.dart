import "package:flutter_dotenv/flutter_dotenv.dart";

/// Logger設定管理クラス
/// 
/// ログシステムの各種設定を一元管理し、
/// 環境変数や実行時からの変更を可能にする
class LoggerConfig {
  // === デフォルト設定値 ===
  static int _bufferSize = 100;
  static int _flushIntervalSeconds = 5;
  static int _maxFileSizeMB = 10;
  static int _maxRetryAttempts = 3;
  static int _defaultCleanupDays = 30;
  
  // === アクセッサー ===
  
  /// バッファサイズ
  static int get bufferSize => _bufferSize;
  
  /// フラッシュ間隔（秒）
  static int get flushIntervalSeconds => _flushIntervalSeconds;
  
  /// 最大ファイルサイズ（バイト）
  static int get maxFileSizeBytes => _maxFileSizeMB * 1024 * 1024;
  
  /// 最大ファイルサイズ（MB）
  static int get maxFileSizeMB => _maxFileSizeMB;
  
  /// 最大リトライ回数
  static int get maxRetryAttempts => _maxRetryAttempts;
  
  /// デフォルトクリーンアップ日数
  static int get defaultCleanupDays => _defaultCleanupDays;
  
  // === 設定変更メソッド ===
  
  /// バッファサイズを設定
  static void setBufferSize(int size) {
    if (size > 0 && size <= 1000) {
      _bufferSize = size;
    }
  }
  
  /// フラッシュ間隔を設定
  static void setFlushInterval(int seconds) {
    if (seconds > 0 && seconds <= 60) {
      _flushIntervalSeconds = seconds;
    }
  }
  
  /// 最大ファイルサイズを設定（MB）
  static void setMaxFileSize(int sizeMB) {
    if (sizeMB > 0 && sizeMB <= 100) {
      _maxFileSizeMB = sizeMB;
    }
  }
  
  /// 最大リトライ回数を設定
  static void setMaxRetryAttempts(int attempts) {
    if (attempts > 0 && attempts <= 10) {
      _maxRetryAttempts = attempts;
    }
  }
  
  /// デフォルトクリーンアップ日数を設定
  static void setDefaultCleanupDays(int days) {
    if (days > 0 && days <= 365) {
      _defaultCleanupDays = days;
    }
  }
  
  // === 環境変数からの読み込み ===
  
  /// 環境変数から設定を読み込み
  static void loadFromEnvironment() {
    // バッファサイズ
    final String? bufferSizeStr = dotenv.env["LOG_BUFFER_SIZE"];
    if (bufferSizeStr != null) {
      final int? bufferSize = int.tryParse(bufferSizeStr);
      if (bufferSize != null) {
        setBufferSize(bufferSize);
      }
    }
    
    // フラッシュ間隔
    final String? flushIntervalStr = dotenv.env["LOG_FLUSH_INTERVAL"];
    if (flushIntervalStr != null) {
      final int? flushInterval = int.tryParse(flushIntervalStr);
      if (flushInterval != null) {
        setFlushInterval(flushInterval);
      }
    }
    
    // 最大ファイルサイズ
    final String? maxFileSizeStr = dotenv.env["LOG_MAX_FILE_SIZE_MB"];
    if (maxFileSizeStr != null) {
      final int? maxFileSize = int.tryParse(maxFileSizeStr);
      if (maxFileSize != null) {
        setMaxFileSize(maxFileSize);
      }
    }
    
    // 最大リトライ回数
    final String? maxRetriesStr = dotenv.env["LOG_MAX_RETRY_ATTEMPTS"];
    if (maxRetriesStr != null) {
      final int? maxRetries = int.tryParse(maxRetriesStr);
      if (maxRetries != null) {
        setMaxRetryAttempts(maxRetries);
      }
    }
    
    // クリーンアップ日数
    final String? cleanupDaysStr = dotenv.env["LOG_CLEANUP_DAYS"];
    if (cleanupDaysStr != null) {
      final int? cleanupDays = int.tryParse(cleanupDaysStr);
      if (cleanupDays != null) {
        setDefaultCleanupDays(cleanupDays);
      }
    }
  }
  
  /// 現在の設定をMapで取得
  static Map<String, dynamic> toMap() => <String, dynamic>{
      "bufferSize": _bufferSize,
      "flushIntervalSeconds": _flushIntervalSeconds,
      "maxFileSizeMB": _maxFileSizeMB,
      "maxRetryAttempts": _maxRetryAttempts,
      "defaultCleanupDays": _defaultCleanupDays,
      "maxFileSizeBytes": maxFileSizeBytes,
    };
  
  /// 設定を文字列で表示（デバッグ用）
  static String toDebugString() {
    final Map<String, dynamic> config = toMap();
    final StringBuffer buffer = StringBuffer("LoggerConfig:\n");
    
    config.forEach((String key, dynamic value) {
      buffer.writeln("  $key: $value");
    });
    
    return buffer.toString();
  }
}

/// Logger パフォーマンス統計追跡クラス
/// 
/// ログシステムの性能と動作状況を監視し、
/// 運用時の問題の早期発見とパフォーマンス最適化を支援
class LoggerPerformanceStats {
  // === 統計データ ===
  static int _totalLogsProcessed = 0;
  static int _totalFlushOperations = 0;
  static int _totalFailedFlushes = 0;
  static int _totalRetryAttempts = 0;
  static DateTime? _lastFlushTime;
  static Duration _totalFlushTime = Duration.zero;
  static DateTime? _initializationTime;
  static final List<Duration> _recentFlushTimes = <Duration>[];
  static const int _maxRecentFlushTimes = 10;
  
  // === 統計更新メソッド ===
  
  /// ログ処理数をインクリメント
  static void incrementLogsProcessed() {
    _totalLogsProcessed++;
  }
  
  /// フラッシュ操作開始時に呼び出し
  static DateTime markFlushStart() => DateTime.now();
  
  /// フラッシュ操作完了時に呼び出し
  static void markFlushComplete(DateTime startTime, {bool success = true}) {
    final DateTime endTime = DateTime.now();
    final Duration flushDuration = endTime.difference(startTime);
    
    _totalFlushOperations++;
    _lastFlushTime = endTime;
    _totalFlushTime += flushDuration;
    
    // 最近のフラッシュ時間を記録（最大10件）
    _recentFlushTimes.add(flushDuration);
    if (_recentFlushTimes.length > _maxRecentFlushTimes) {
      _recentFlushTimes.removeAt(0);
    }
    
    if (!success) {
      _totalFailedFlushes++;
    }
  }
  
  /// リトライ試行をカウント
  static void incrementRetryAttempts() {
    _totalRetryAttempts++;
  }
  
  /// 初期化時刻を記録
  static void markInitialization() {
    _initializationTime = DateTime.now();
  }
  
  // === 統計取得メソッド ===
  
  /// 基本統計情報を取得
  static Map<String, dynamic> getBasicStats() => <String, dynamic>{
      "totalLogsProcessed": _totalLogsProcessed,
      "totalFlushOperations": _totalFlushOperations,
      "totalFailedFlushes": _totalFailedFlushes,
      "totalRetryAttempts": _totalRetryAttempts,
      "lastFlushTime": _lastFlushTime?.toIso8601String(),
      "initializationTime": _initializationTime?.toIso8601String(),
    };
  
  /// パフォーマンス統計を取得
  static Map<String, dynamic> getPerformanceStats() {
    final Map<String, dynamic> stats = <String, dynamic>{};
    
    // 平均フラッシュ時間
    if (_totalFlushOperations > 0) {
      stats["averageFlushTimeMs"] = 
          (_totalFlushTime.inMilliseconds / _totalFlushOperations).toStringAsFixed(2);
    } else {
      stats["averageFlushTimeMs"] = "0";
    }
    
    // 最近のフラッシュ時間統計
    if (_recentFlushTimes.isNotEmpty) {
      final List<int> recentMs = _recentFlushTimes.map((Duration d) => d.inMilliseconds).toList();
      stats["recentFlushTimesMs"] = recentMs;
      stats["recentAverageFlushTimeMs"] = 
          (recentMs.reduce((int a, int b) => a + b) / recentMs.length).toStringAsFixed(2);
      stats["recentMaxFlushTimeMs"] = recentMs.reduce((int a, int b) => a > b ? a : b);
      stats["recentMinFlushTimeMs"] = recentMs.reduce((int a, int b) => a < b ? a : b);
    }
    
    // 失敗率
    if (_totalFlushOperations > 0) {
      stats["failureRatePercent"] = 
          ((_totalFailedFlushes / _totalFlushOperations) * 100).toStringAsFixed(2);
    } else {
      stats["failureRatePercent"] = "0";
    }
    
    // リトライ率
    if (_totalLogsProcessed > 0) {
      stats["retryRatePercent"] = 
          ((_totalRetryAttempts / _totalLogsProcessed) * 100).toStringAsFixed(2);
    } else {
      stats["retryRatePercent"] = "0";
    }
    
    // 稼働時間
    if (_initializationTime != null) {
      final Duration uptime = DateTime.now().difference(_initializationTime!);
      stats["uptimeSeconds"] = uptime.inSeconds;
      stats["uptimeHours"] = (uptime.inSeconds / 3600).toStringAsFixed(2);
    }
    
    return stats;
  }
  
  /// 全統計情報を取得
  static Map<String, dynamic> getAllStats() {
    final Map<String, dynamic> basicStats = getBasicStats();
    final Map<String, dynamic> performanceStats = getPerformanceStats();
    
    return <String, dynamic>{
      "basic": basicStats,
      "performance": performanceStats,
      "timestamp": DateTime.now().toIso8601String(),
    };
  }
  
  /// 健康状態チェック
  static Map<String, dynamic> getHealthCheck() {
    final Map<String, dynamic> health = <String, dynamic>{};
    
    // フラッシュ失敗率チェック
    final double failureRate = _totalFlushOperations > 0 
        ? (_totalFailedFlushes / _totalFlushOperations) * 100 
        : 0.0;
    
    health["flushHealthy"] = failureRate < 5.0; // 5%未満なら健康
    health["failureRate"] = failureRate.toStringAsFixed(2);
    
    // 最近の処理時間チェック
    if (_recentFlushTimes.isNotEmpty) {
      final double avgRecentTime = _recentFlushTimes
          .map((Duration d) => d.inMilliseconds)
          .reduce((int a, int b) => a + b) / _recentFlushTimes.length;
      
      health["performanceHealthy"] = avgRecentTime < 1000; // 1秒未満なら健康
      health["recentAverageTimeMs"] = avgRecentTime.toStringAsFixed(2);
    } else {
      health["performanceHealthy"] = true;
      health["recentAverageTimeMs"] = "0";
    }
    
    // 最後のフラッシュ時刻チェック
    if (_lastFlushTime != null) {
      final Duration timeSinceLastFlush = DateTime.now().difference(_lastFlushTime!);
      health["flushRecency"] = timeSinceLastFlush.inMinutes < 10; // 10分以内なら健康
      health["minutesSinceLastFlush"] = timeSinceLastFlush.inMinutes;
    } else {
      health["flushRecency"] = false;
      health["minutesSinceLastFlush"] = -1;
    }
    
    // 総合健康状態
    health["overallHealthy"] = health["flushHealthy"] == true && 
                               health["performanceHealthy"] == true && 
                               health["flushRecency"] == true;
    
    return health;
  }
  
  /// 統計をリセット
  static void reset() {
    _totalLogsProcessed = 0;
    _totalFlushOperations = 0;
    _totalFailedFlushes = 0;
    _totalRetryAttempts = 0;
    _lastFlushTime = null;
    _totalFlushTime = Duration.zero;
    _initializationTime = null;
    _recentFlushTimes.clear();
  }
  
  /// デバッグ用の詳細表示
  static String toDebugString() {
    final Map<String, dynamic> allStats = getAllStats();
    final StringBuffer buffer = StringBuffer("LoggerPerformanceStats:\n");
    
    buffer.writeln("=== Basic Stats ===");
    final Map<String, dynamic> basic = allStats["basic"] as Map<String, dynamic>;
    basic.forEach((String key, dynamic value) {
      buffer.writeln("  $key: $value");
    });
    
    buffer.writeln("=== Performance Stats ===");
    final Map<String, dynamic> performance = allStats["performance"] as Map<String, dynamic>;
    performance.forEach((String key, dynamic value) {
      buffer.writeln("  $key: $value");
    });
    
    buffer.writeln("=== Health Check ===");
    final Map<String, dynamic> health = getHealthCheck();
    health.forEach((String key, dynamic value) {
      buffer.writeln("  $key: $value");
    });
    
    return buffer.toString();
  }
}