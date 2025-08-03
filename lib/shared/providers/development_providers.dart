import "dart:async";

import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../core/utils/provider_logger.dart";

part "development_providers.g.dart";

/// 開発・デバッグ用プロバイダー

/// デバッグモード制御（本番では無効）
@riverpod
class DebugModeControl extends _$DebugModeControl with ProviderLoggerMixin {
  @override
  String get providerComponent => "DebugModeControl";
  
  @override
  bool build() {
    // 本番環境では常にfalse
    if (kReleaseMode) {
      logInfo("本番モードではデバッグモードを無効化");
      return false;
    }
    
    ref.keepAlive();
    logInfo("デバッグモード制御を初期化しました");
    return kDebugMode; // デバッグビルドでのみ有効
  }

  void toggle() {
    if (!kReleaseMode) {
      logDebug("デバッグモードを切り替え: ${!state}");
      state = !state;
    }
  }
}

/// パフォーマンス監視プロバイダー
@riverpod
class PerformanceMonitor extends _$PerformanceMonitor with ProviderLoggerMixin {
  @override
  String get providerComponent => "PerformanceMonitor";
  
  @override
  PerformanceMetrics build() {
    if (kReleaseMode) {
      logInfo("本番モードではパフォーマンス監視を無効化");
      return const PerformanceMetrics(); // 本番では無効
    }
    
    ref.keepAlive();
    
    logInfo("パフォーマンス監視を開始しました");
    _startPerformanceMonitoring();
    
    return const PerformanceMetrics();
  }

  void _startPerformanceMonitoring() {
    logDebug("パフォーマンス監視の定期実行を開始");
    Timer.periodic(const Duration(seconds: 5), (_) {
      _collectMetrics();
    });
  }

  void _collectMetrics() {
    try {
      // パフォーマンスメトリクス収集
      final PerformanceMetrics metrics = PerformanceMetrics(
        // メモリ使用量、CPU使用率等の収集
        memoryUsageMB: _getMemoryUsage(),
        providerCount: _getActiveProviderCount(),
        lastUpdated: DateTime.now(),
      );
      
      state = metrics;
      logTrace("パフォーマンスメトリクスを更新");
    } catch (e, stackTrace) {
      logError("パフォーマンスメトリクス収集中にエラーが発生", e, stackTrace);
    }
  }

  double _getMemoryUsage() =>
    // メモリ使用量の取得（簡易実装）
    0.0;

  int _getActiveProviderCount() =>
    // アクティブプロバイダー数の取得
    0;
}

class PerformanceMetrics {
  const PerformanceMetrics({
    this.memoryUsageMB = 0.0,
    this.providerCount = 0,
    this.lastUpdated,
  });

  final double memoryUsageMB;
  final int providerCount;
  final DateTime? lastUpdated;

  PerformanceMetrics copyWith({
    double? memoryUsageMB,
    int? providerCount,
    DateTime? lastUpdated,
  }) => PerformanceMetrics(
    memoryUsageMB: memoryUsageMB ?? this.memoryUsageMB,
    providerCount: providerCount ?? this.providerCount,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}