import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";


part "dependency_optimizer.g.dart";

/// プロバイダー依存関係の種類
enum DependencyType {
  /// 強依存（即座に無効化が必要）
  strong,
  
  /// 弱依存（遅延無効化可能）
  weak,
  
  /// 計算依存（結果のみ依存）
  computed,
  
  /// 監視依存（変更監視のみ）
  watch,
}

/// 依存関係の重要度
enum DependencyPriority {
  /// 低優先度（バッチ処理可能）
  low,
  
  /// 通常優先度
  normal,
  
  /// 高優先度（即座に処理）
  high,
  
  /// 緊急優先度（同期処理）
  critical,
}

/// プロバイダー依存関係情報
class ProviderDependency {
  const ProviderDependency({
    required this.sourceId,
    required this.targetId,
    required this.type,
    required this.priority,
    this.debounceMs = 0,
    this.batchable = false,
    this.condition,
  });

  /// 依存元プロバイダーID
  final String sourceId;
  
  /// 依存先プロバイダーID
  final String targetId;
  
  /// 依存関係の種類
  final DependencyType type;
  
  /// 優先度
  final DependencyPriority priority;
  
  /// デバウンス時間（ミリ秒）
  final int debounceMs;
  
  /// バッチ処理可能フラグ
  final bool batchable;
  
  /// 無効化条件（任意）
  final bool Function()? condition;

  @override
  String toString() => "ProviderDependency($sourceId -> $targetId, $type, $priority)";
}

/// 依存関係最適化管理システム
@riverpod
class DependencyOptimizer extends _$DependencyOptimizer {
  final Map<String, List<ProviderDependency>> _dependencies = <String, List<ProviderDependency>>{};
  final Map<String, Timer> _debounceTimers = <String, Timer>{};
  final Map<String, List<String>> _batchQueue = <String, List<String>>{};
  Timer? _batchProcessTimer;

  @override
  Map<String, DependencyStats> build() => <String, DependencyStats>{};

  /// 依存関係を登録
  void registerDependency(ProviderDependency dependency) {
    _dependencies.putIfAbsent(dependency.sourceId, () => <ProviderDependency>[])
        .add(dependency);
    
    // 統計更新
    _updateStats(dependency.sourceId);
  }

  /// 複数の依存関係を一括登録
  void registerMultipleDependencies(List<ProviderDependency> dependencies) {
    for (final ProviderDependency dependency in dependencies) {
      registerDependency(dependency);
    }
  }

  /// プロバイダー変更の処理
  void handleProviderChange(String providerId, {dynamic newValue, dynamic oldValue}) {
    final List<ProviderDependency>? dependencies = _dependencies[providerId];
    if (dependencies == null || dependencies.isEmpty) {
      return;
    }

    // 優先度別にグループ化
    final Map<DependencyPriority, List<ProviderDependency>> priorityGroups = 
        <DependencyPriority, List<ProviderDependency>>{};
    
    for (final ProviderDependency dep in dependencies) {
      // 条件チェック
      if (dep.condition != null && !dep.condition!()) {
        continue;
      }
      
      priorityGroups.putIfAbsent(dep.priority, () => <ProviderDependency>[]).add(dep);
    }

    // 優先度順に処理
    _processByPriority(priorityGroups);
  }

  /// 優先度別処理
  void _processByPriority(Map<DependencyPriority, List<ProviderDependency>> priorityGroups) {
    // 緊急優先度 - 同期処理
    final List<ProviderDependency>? critical = priorityGroups[DependencyPriority.critical];
    if (critical != null) {
      for (final ProviderDependency dep in critical) {
        _invalidateProvider(dep.targetId);
      }
    }

    // 高優先度 - 即座に処理
    final List<ProviderDependency>? high = priorityGroups[DependencyPriority.high];
    if (high != null) {
      for (final ProviderDependency dep in high) {
        if (dep.debounceMs > 0) {
          _scheduleDebounced(dep);
        } else {
          _invalidateProvider(dep.targetId);
        }
      }
    }

    // 通常・低優先度 - バッチ処理可能
    final List<ProviderDependency> batchable = <ProviderDependency>[];
    for (final DependencyPriority priority in <DependencyPriority>[DependencyPriority.normal, DependencyPriority.low]) {
      final List<ProviderDependency>? deps = priorityGroups[priority];
      if (deps != null) {
        batchable.addAll(deps.where((ProviderDependency d) => d.batchable));
        
        // バッチ処理不可能なものは個別処理
        for (final ProviderDependency dep in deps.where((ProviderDependency d) => !d.batchable)) {
          if (dep.debounceMs > 0) {
            _scheduleDebounced(dep);
          } else {
            _invalidateProvider(dep.targetId);
          }
        }
      }
    }

    // バッチ処理
    if (batchable.isNotEmpty) {
      _scheduleBatch(batchable);
    }
  }

  /// デバウンス処理のスケジュール
  void _scheduleDebounced(ProviderDependency dependency) {
    final String key = "${dependency.sourceId}_${dependency.targetId}";
    
    // 既存タイマーをキャンセル
    _debounceTimers[key]?.cancel();
    
    // 新しいタイマーをセット
    _debounceTimers[key] = Timer(Duration(milliseconds: dependency.debounceMs), () {
      _invalidateProvider(dependency.targetId);
      _debounceTimers.remove(key);
    });
  }

  /// バッチ処理のスケジュール
  void _scheduleBatch(List<ProviderDependency> dependencies) {
    for (final ProviderDependency dep in dependencies) {
      _batchQueue.putIfAbsent(dep.targetId, () => <String>[]).add(dep.sourceId);
    }

    // バッチタイマーが未設定の場合のみ設定
    _batchProcessTimer ??= Timer(const Duration(milliseconds: 50), () {
      _processBatch();
      _batchProcessTimer = null;
    });
  }

  /// バッチ処理実行
  void _processBatch() {
    final List<String> targetIds = _batchQueue.keys.toList()
      ..sort((String a, String b) {
        final int aComplexity = _batchQueue[a]?.length ?? 0;
        final int bComplexity = _batchQueue[b]?.length ?? 0;
        return aComplexity.compareTo(bComplexity); // 単純なものから処理
      });

    for (final String targetId in targetIds) {
      _invalidateProvider(targetId);
    }

    _batchQueue.clear();
  }

  /// プロバイダー無効化（実際の無効化は外部で実装）
  void _invalidateProvider(String providerId) {
    // 統計更新
    _updateInvalidationStats(providerId);
    
    // 実際の無効化処理はここに実装
    // ref.invalidate() などを呼び出す
  }

  /// 統計更新
  void _updateStats(String providerId) {
    final List<ProviderDependency> deps = _dependencies[providerId] ?? <ProviderDependency>[];
    final DependencyStats stats = DependencyStats(
      providerId: providerId,
      dependencyCount: deps.length,
      strongDependencies: deps.where((ProviderDependency d) => d.type == DependencyType.strong).length,
      weakDependencies: deps.where((ProviderDependency d) => d.type == DependencyType.weak).length,
      computedDependencies: deps.where((ProviderDependency d) => d.type == DependencyType.computed).length,
      watchDependencies: deps.where((ProviderDependency d) => d.type == DependencyType.watch).length,
      invalidationCount: state[providerId]?.invalidationCount ?? 0,
    );

    state = <String, DependencyStats>{...state, providerId: stats};
  }

  /// 無効化統計更新
  void _updateInvalidationStats(String providerId) {
    final DependencyStats? currentStats = state[providerId];
    if (currentStats != null) {
      final DependencyStats updatedStats = currentStats.copyWith(
        invalidationCount: currentStats.invalidationCount + 1,
        lastInvalidated: DateTime.now(),
      );
      state = <String, DependencyStats>{...state, providerId: updatedStats};
    }
  }

  /// 循環依存検出
  List<List<String>> detectCircularDependencies() {
    final List<List<String>> cycles = <List<String>>[];
    final Set<String> visited = <String>{};
    final Set<String> recursionStack = <String>{};

    for (final String providerId in _dependencies.keys) {
      if (!visited.contains(providerId)) {
        _detectCyclesDFS(providerId, visited, recursionStack, <String>[], cycles);
      }
    }

    return cycles;
  }

  /// 深度優先探索による循環依存検出
  void _detectCyclesDFS(
    String providerId,
    Set<String> visited,
    Set<String> recursionStack,
    List<String> path,
    List<List<String>> cycles,
  ) {
    visited.add(providerId);
    recursionStack.add(providerId);
    path.add(providerId);

    final List<ProviderDependency>? dependencies = _dependencies[providerId];
    if (dependencies != null) {
      for (final ProviderDependency dep in dependencies) {
        if (!visited.contains(dep.targetId)) {
          _detectCyclesDFS(dep.targetId, visited, recursionStack, path, cycles);
        } else if (recursionStack.contains(dep.targetId)) {
          // 循環依存を発見
          final int cycleStartIndex = path.indexOf(dep.targetId);
          cycles.add(path.sublist(cycleStartIndex) + <String>[dep.targetId]);
        }
      }
    }

    recursionStack.remove(providerId);
    path.removeLast();
  }

  /// 最適化推奨事項を取得
  List<OptimizationRecommendation> getOptimizationRecommendations() {
    final List<OptimizationRecommendation> recommendations = <OptimizationRecommendation>[];

    // 循環依存の警告
    final List<List<String>> cycles = detectCircularDependencies();
    for (final List<String> cycle in cycles) {
      recommendations.add(OptimizationRecommendation(
        type: RecommendationType.warning,
        message: "循環依存が検出されました: ${cycle.join(' -> ')}",
        severity: OptimizationSeverity.high,
        providerId: cycle.first,
      ));
    }

    // 過剰な依存関係の警告
    for (final MapEntry<String, DependencyStats> entry in state.entries) {
      if (entry.value.dependencyCount > 10) {
        recommendations.add(OptimizationRecommendation(
          type: RecommendationType.optimization,
          message: "${entry.key}の依存関係が多すぎます (${entry.value.dependencyCount}個)",
          severity: OptimizationSeverity.medium,
          providerId: entry.key,
        ));
      }

      if (entry.value.invalidationCount > 100) {
        recommendations.add(OptimizationRecommendation(
          type: RecommendationType.performance,
          message: "${entry.key}の無効化が頻繁すぎます (${entry.value.invalidationCount}回)",
          severity: OptimizationSeverity.high,
          providerId: entry.key,
        ));
      }
    }

    return recommendations;
  }

  /// リソースクリーンアップ
  void dispose() {
    for (final Timer timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    
    _batchProcessTimer?.cancel();
    _batchQueue.clear();
    
    _dependencies.clear();
  }
}

/// プロバイダー統計情報
class DependencyStats {
  const DependencyStats({
    required this.providerId,
    required this.dependencyCount,
    required this.strongDependencies,
    required this.weakDependencies,
    required this.computedDependencies,
    required this.watchDependencies,
    required this.invalidationCount,
    this.lastInvalidated,
  });

  final String providerId;
  final int dependencyCount;
  final int strongDependencies;
  final int weakDependencies;
  final int computedDependencies;
  final int watchDependencies;
  final int invalidationCount;
  final DateTime? lastInvalidated;

  DependencyStats copyWith({
    String? providerId,
    int? dependencyCount,
    int? strongDependencies,
    int? weakDependencies,
    int? computedDependencies,
    int? watchDependencies,
    int? invalidationCount,
    DateTime? lastInvalidated,
  }) => DependencyStats(
    providerId: providerId ?? this.providerId,
    dependencyCount: dependencyCount ?? this.dependencyCount,
    strongDependencies: strongDependencies ?? this.strongDependencies,
    weakDependencies: weakDependencies ?? this.weakDependencies,
    computedDependencies: computedDependencies ?? this.computedDependencies,
    watchDependencies: watchDependencies ?? this.watchDependencies,
    invalidationCount: invalidationCount ?? this.invalidationCount,
    lastInvalidated: lastInvalidated ?? this.lastInvalidated,
  );
}

/// 最適化推奨事項
class OptimizationRecommendation {
  const OptimizationRecommendation({
    required this.type,
    required this.message,
    required this.severity,
    required this.providerId,
  });

  final RecommendationType type;
  final String message;
  final OptimizationSeverity severity;
  final String providerId;
}

/// 推奨事項の種類
enum RecommendationType {
  warning,
  optimization,
  performance,
  memory,
}

/// 最適化の重要度
enum OptimizationSeverity {
  low,
  medium,
  high,
  critical,
}

/// 依存関係最適化用ミックスイン
mixin DependencyOptimizationMixin {
  /// 依存関係を登録
  void registerOptimizedDependency(
    Ref ref,
    String sourceId,
    String targetId,
    DependencyType type, {
    DependencyPriority priority = DependencyPriority.normal,
    int debounceMs = 0,
    bool batchable = false,
    bool Function()? condition,
  }) {
    ref.read(dependencyOptimizerProvider.notifier)
      .registerDependency(ProviderDependency(
      sourceId: sourceId,
      targetId: targetId,
      type: type,
      priority: priority,
      debounceMs: debounceMs,
      batchable: batchable,
      condition: condition,
    ));
  }

  /// プロバイダー変更通知
  void notifyProviderChange(Ref ref, String providerId, {dynamic newValue, dynamic oldValue}) {
    ref.read(dependencyOptimizerProvider.notifier)
      .handleProviderChange(providerId, newValue: newValue, oldValue: oldValue);
  }
}

/// 自動依存関係検出プロバイダー
@riverpod
class AutoDependencyDetector extends _$AutoDependencyDetector {
  @override
  Map<String, Set<String>> build() => <String, Set<String>>{};

  /// プロバイダーのwatch関係を記録
  void recordWatch(String sourceId, String targetId) {
    state = <String, Set<String>>{
      ...state,
      sourceId: (state[sourceId] ?? <String>{})..add(targetId),
    };
  }

  /// 推測される依存関係を取得
  List<ProviderDependency> getInferredDependencies() {
    final List<ProviderDependency> dependencies = <ProviderDependency>[];

    for (final MapEntry<String, Set<String>> entry in state.entries) {
      for (final String targetId in entry.value) {
        dependencies.add(ProviderDependency(
          sourceId: entry.key,
          targetId: targetId,
          type: DependencyType.watch,
          priority: DependencyPriority.normal,
          batchable: true,
        ));
      }
    }

    return dependencies;
  }
}