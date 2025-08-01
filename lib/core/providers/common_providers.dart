import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../constants/constants.dart";

part "common_providers.g.dart";

/// グローバルエラー管理プロバイダー
/// アプリケーション全体のエラー状態を管理
@riverpod
class GlobalError extends _$GlobalError {
  @override
  String? build() => null;

  /// エラーを設定
  void setError(String error) {
    state = error;
  }

  /// 例外からエラーを設定
  void setErrorFromException(Exception exception) {
    if (exception is ValidationException) {
      state = exception.message;
    } else if (exception is AuthException) {
      state = exception.message;
    } else if (exception is YataException) {
      state = exception.message;
    } else {
      state = "予期しないエラーが発生しました: ${exception.toString()}";
    }
  }

  /// エラーをクリア
  void clearError() {
    state = null;
  }

  /// エラーの有無を確認
  bool get hasError => state != null;
}

/// グローバルローディング状態プロバイダー
/// アプリケーション全体のローディング状態を管理
@riverpod
class GlobalLoading extends _$GlobalLoading {
  @override
  bool build() => false;

  /// ローディング状態を設定
  void setLoading(bool loading) {
    state = loading;
  }

  /// ローディングを開始
  void startLoading() {
    state = true;
  }

  /// ローディングを停止
  void stopLoading() {
    state = false;
  }

  /// ローディング状態を一時的に設定（指定時間後に自動停止）
  void setTemporaryLoading(Duration duration) {
    state = true;
    // ignore: unused_local_variable
    final Future<void> delayed = Future<void>.delayed(duration, () {
      state = false;
    });
    ref.onDispose(() {
      // プロバイダー破棄時にタイマーをキャンセル
    });
  }
}

/// メニュー関連ローディング状態プロバイダー
@riverpod
class MenuLoading extends _$MenuLoading {
  @override
  bool build() => false;

  void setLoading(bool loading) {
    state = loading;
  }
}

/// 注文関連ローディング状態プロバイダー
@riverpod
class OrderLoading extends _$OrderLoading {
  @override
  bool build() => false;

  void setLoading(bool loading) {
    state = loading;
  }
}

/// 在庫関連ローディング状態プロバイダー
@riverpod
class InventoryLoading extends _$InventoryLoading {
  @override
  bool build() => false;

  void setLoading(bool loading) {
    state = loading;
  }
}

/// 成功メッセージ管理プロバイダー
/// 操作成功時のフィードバックメッセージを管理
@riverpod
class SuccessMessage extends _$SuccessMessage {
  @override
  String? build() => null;

  /// 成功メッセージを設定
  void setMessage(String message) {
    state = message;
    // 5秒後に自動的にクリア
    // ignore: unused_local_variable
    final Future<void> delayed = Future<void>.delayed(AppConfig.messageDisplayDuration, clearMessage);
    ref.onDispose(() {
      // プロバイダー破棄時にタイマーをキャンセル
    });
  }

  /// メッセージをクリア
  void clearMessage() {
    state = null;
  }

  /// メッセージの有無を確認
  bool get hasMessage => state != null;
}

/// ネットワーク状態プロバイダー
/// オンライン/オフライン状態を管理
@riverpod
class NetworkStatus extends _$NetworkStatus {
  @override
  bool build() => true; // デフォルトはオンライン状態

  /// ネットワーク状態を設定
  void setOnline(bool isOnline) {
    state = isOnline;
  }

  /// オンライン状態にする
  void setOnlineStatus() {
    state = true;
  }

  /// オフライン状態にする
  void setOfflineStatus() {
    state = false;
  }

  /// オンライン状態かどうか
  bool get isOnline => state;

  /// オフライン状態かどうか
  bool get isOffline => !state;
}

/// 警告メッセージ管理プロバイダー
/// 警告レベルのメッセージを管理
@riverpod
class WarningMessage extends _$WarningMessage {
  @override
  String? build() => null;

  /// 警告メッセージを設定
  void setMessage(String message) {
    state = message;
  }

  /// メッセージをクリア
  void clearMessage() {
    state = null;
  }

  /// メッセージの有無を確認
  bool get hasMessage => state != null;
}

/// キャッシュ状態データクラス
class CacheStatusData {
  const CacheStatusData({
    this.enabled = false,
    this.memoryItems = 0,
    this.memorySizeMB = 0.0,
    this.ttlItems = 0,
    this.lastCleanup,
    this.lastUpdated,
    this.lastCleared,
  });

  final bool enabled;
  final int memoryItems;
  final double memorySizeMB;
  final int ttlItems;
  final DateTime? lastCleanup;
  final DateTime? lastUpdated;
  final DateTime? lastCleared;

  CacheStatusData copyWith({
    bool? enabled,
    int? memoryItems,
    double? memorySizeMB,
    int? ttlItems,
    DateTime? lastCleanup,
    DateTime? lastUpdated,
    DateTime? lastCleared,
  }) => CacheStatusData(
    enabled: enabled ?? this.enabled,
    memoryItems: memoryItems ?? this.memoryItems,
    memorySizeMB: memorySizeMB ?? this.memorySizeMB,
    ttlItems: ttlItems ?? this.ttlItems,
    lastCleanup: lastCleanup ?? this.lastCleanup,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    lastCleared: lastCleared ?? this.lastCleared,
  );
}

/// キャッシュ状態管理プロバイダー
/// UI層でのキャッシュ状態表示用（Repository層の統計情報を表示）
@riverpod
class CacheStatus extends _$CacheStatus {
  @override
  CacheStatusData build() => const CacheStatusData();

  /// キャッシュ統計情報の更新
  /// Repository層から呼び出される（間接的にService経由）
  void updateStats(Map<String, dynamic> stats) {
    state = state.copyWith(
      enabled: true,
      memoryItems: stats["memory_items"] as int? ?? state.memoryItems,
      memorySizeMB: stats["memory_size_mb"] as double? ?? state.memorySizeMB,
      ttlItems: stats["ttl_items"] as int? ?? state.ttlItems,
      lastUpdated: DateTime.now(),
    );
  }

  /// キャッシュクリア完了通知
  void notifyCacheCleared() {
    state = state.copyWith(
      memoryItems: 0,
      ttlItems: 0,
      lastCleared: DateTime.now(),
    );
  }
}

/// キャッシュパフォーマンスデータクラス
class CachePerformanceData {
  const CachePerformanceData({
    this.hits = 0,
    this.misses = 0,
    this.totalRequests = 0,
  });

  final int hits;
  final int misses;
  final int totalRequests;

  /// ヒット率計算
  double get hitRate => totalRequests > 0 ? hits / totalRequests : 0.0;

  /// ミス率計算
  double get missRate => totalRequests > 0 ? misses / totalRequests : 0.0;

  CachePerformanceData copyWith({
    int? hits,
    int? misses,
    int? totalRequests,
  }) => CachePerformanceData(
    hits: hits ?? this.hits,
    misses: misses ?? this.misses,
    totalRequests: totalRequests ?? this.totalRequests,
  );
}

/// キャッシュパフォーマンス監視プロバイダー
/// UI層でのパフォーマンス表示用
@riverpod 
class CachePerformance extends _$CachePerformance {
  @override
  CachePerformanceData build() => const CachePerformanceData();

  /// キャッシュヒット記録
  void recordHit() {
    state = state.copyWith(
      hits: state.hits + 1,
      totalRequests: state.totalRequests + 1,
    );
  }

  /// キャッシュミス記録
  void recordMiss() {
    state = state.copyWith(
      misses: state.misses + 1,
      totalRequests: state.totalRequests + 1,
    );
  }

  /// 統計リセット
  void resetStats() {
    state = const CachePerformanceData();
  }
}

/// 確認ダイアログ状態プロバイダー
/// 確認ダイアログの表示状態を管理
class ConfirmationDialogState {
  const ConfirmationDialogState({
    required this.isVisible,
    this.title,
    this.message,
    this.onConfirm,
    this.onCancel,
  });

  final bool isVisible;
  final String? title;
  final String? message;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  ConfirmationDialogState copyWith({
    bool? isVisible,
    String? title,
    String? message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) => ConfirmationDialogState(
    isVisible: isVisible ?? this.isVisible,
    title: title ?? this.title,
    message: message ?? this.message,
    onConfirm: onConfirm ?? this.onConfirm,
    onCancel: onCancel ?? this.onCancel,
  );
}

@riverpod
class ConfirmationDialog extends _$ConfirmationDialog {
  @override
  ConfirmationDialogState build() => const ConfirmationDialogState(isVisible: false);

  /// 確認ダイアログを表示
  void showDialog({
    String? title,
    String? message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    state = ConfirmationDialogState(
      isVisible: true,
      title: title,
      message: message,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// ダイアログを非表示
  void hideDialog() {
    state = const ConfirmationDialogState(isVisible: false);
  }

  /// 確認ボタンが押された時の処理
  void confirm() {
    state.onConfirm?.call();
    hideDialog();
  }

  /// キャンセルボタンが押された時の処理
  void cancel() {
    state.onCancel?.call();
    hideDialog();
  }
}
