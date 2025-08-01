import "dart:async";

import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "development_providers.g.dart";

/// 開発・デバッグ用プロバイダー

/// デバッグモード制御（本番では無効）
@riverpod
class DebugModeControl extends _$DebugModeControl {
  @override
  bool build() {
    // 本番環境では常にfalse
    if (kReleaseMode) {
      return false;
    }
    
    ref.keepAlive();
    return kDebugMode; // デバッグビルドでのみ有効
  }

  void toggle() {
    if (!kReleaseMode) {
      state = !state;
    }
  }
}

/// パフォーマンス監視プロバイダー
@riverpod
class PerformanceMonitor extends _$PerformanceMonitor {
  @override
  PerformanceMetrics build() {
    if (kReleaseMode) {
      return const PerformanceMetrics(); // 本番では無効
    }
    
    ref.keepAlive();
    
    _startPerformanceMonitoring();
    
    return const PerformanceMetrics();
  }

  void _startPerformanceMonitoring() {
    Timer.periodic(const Duration(seconds: 5), (_) {
      _collectMetrics();
    });
  }

  void _collectMetrics() {
    // パフォーマンスメトリクス収集
    final PerformanceMetrics metrics = PerformanceMetrics(
      // メモリ使用量、CPU使用率等の収集
      memoryUsageMB: _getMemoryUsage(),
      providerCount: _getActiveProviderCount(),
      lastUpdated: DateTime.now(),
    );
    
    state = metrics;
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