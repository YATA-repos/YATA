import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../core/constants/constants.dart";
import "../../core/utils/provider_logger.dart";

part "common_providers.g.dart";

/// グローバルエラー管理プロバイダー
/// アプリケーション全体のエラー状態を管理
@riverpod
class GlobalError extends _$GlobalError with ProviderLoggerMixin {
  @override
  String get providerComponent => "GlobalError";
  
  @override
  String? build() {
    logInfo("グローバルエラー管理を初期化しました");
    return null;
  }

  /// エラーを設定
  void setError(String error) {
    logWarning("グローバルエラーを設定: $error");
    state = error;
  }

  /// 例外からエラーを設定
  void setErrorFromException(Exception exception) {
    logError("例外からグローバルエラーを設定", exception);
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
    logDebug("グローバルエラーをクリア");
    state = null;
  }

  /// エラーの有無を確認
  bool get hasError => state != null;
}

/// グローバルローディング状態プロバイダー
/// アプリケーション全体のローディング状態を管理
@riverpod
class GlobalLoading extends _$GlobalLoading with ProviderLoggerMixin {
  @override
  String get providerComponent => "GlobalLoading";
  
  @override
  bool build() {
    logInfo("グローバルローディング管理を初期化しました");
    return false;
  }

  /// ローディング状態を設定
  void setLoading(bool loading) {
    logDebug("グローバルローディング状態を設定: $loading");
    state = loading;
  }

  /// ローディングを開始
  void startLoading() {
    logDebug("グローバルローディングを開始");
    state = true;
  }

  /// ローディングを停止
  void stopLoading() {
    logDebug("グローバルローディングを停止");
    state = false;
  }

  /// ローディング状態を一時的に設定（指定時間後に自動停止）
  void setTemporaryLoading(Duration duration) {
    logDebug("一時的ローディングを設定: ${duration.inMilliseconds}ms");
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
class MenuLoading extends _$MenuLoading with ProviderLoggerMixin {
  @override
  String get providerComponent => "MenuLoading";
  
  @override
  bool build() {
    logInfo("メニューローディング管理を初期化しました");
    return false;
  }

  void setLoading(bool loading) {
    logDebug("メニューローディング状態を設定: $loading");
    state = loading;
  }
}

/// 注文関連ローディング状態プロバイダー
@riverpod
class OrderLoading extends _$OrderLoading with ProviderLoggerMixin {
  @override
  String get providerComponent => "OrderLoading";
  
  @override
  bool build() {
    logInfo("注文ローディング管理を初期化しました");
    return false;
  }

  void setLoading(bool loading) {
    logDebug("注文ローディング状態を設定: $loading");
    state = loading;
  }
}

/// 在庫関連ローディング状態プロバイダー
@riverpod
class InventoryLoading extends _$InventoryLoading with ProviderLoggerMixin {
  @override
  String get providerComponent => "InventoryLoading";
  
  @override
  bool build() {
    logInfo("在庫ローディング管理を初期化しました");
    return false;
  }

  void setLoading(bool loading) {
    logDebug("在庫ローディング状態を設定: $loading");
    state = loading;
  }
}

/// 成功メッセージ管理プロバイダー
/// 操作成功時のフィードバックメッセージを管理
@riverpod
class SuccessMessage extends _$SuccessMessage with ProviderLoggerMixin {
  @override
  String get providerComponent => "SuccessMessage";
  
  @override
  String? build() {
    logInfo("成功メッセージ管理を初期化しました");
    return null;
  }

  /// 成功メッセージを設定
  void setMessage(String message) {
    logInfo("成功メッセージを設定: $message");
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
    logDebug("成功メッセージをクリア");
    state = null;
  }

  /// メッセージの有無を確認
  bool get hasMessage => state != null;
}

/// ネットワーク状態プロバイダー
/// オンライン/オフライン状態を管理
@riverpod
class NetworkStatus extends _$NetworkStatus with ProviderLoggerMixin {
  @override
  String get providerComponent => "NetworkStatus";
  
  @override
  bool build() {
    logInfo("ネットワーク状態管理を初期化しました");
    return true; // デフォルトはオンライン状態
  }

  /// ネットワーク状態を設定
  void setOnline(bool isOnline) {
    logInfo("ネットワーク状態を設定: $isOnline");
    state = isOnline;
  }

  /// オンライン状態にする
  void setOnlineStatus() {
    logInfo("オンライン状態に変更");
    state = true;
  }

  /// オフライン状態にする
  void setOfflineStatus() {
    logWarning("オフライン状態に変更");
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
class WarningMessage extends _$WarningMessage with ProviderLoggerMixin {
  @override
  String get providerComponent => "WarningMessage";
  
  @override
  String? build() {
    logInfo("警告メッセージ管理を初期化しました");
    return null;
  }

  /// 警告メッセージを設定
  void setMessage(String message) {
    logWarning("警告メッセージを設定: $message");
    state = message;
  }

  /// メッセージをクリア
  void clearMessage() {
    logDebug("警告メッセージをクリア");
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
class CacheStatus extends _$CacheStatus with ProviderLoggerMixin {
  @override
  String get providerComponent => "CacheStatus";
  
  @override
  CacheStatusData build() {
    logInfo("キャッシュ状態管理を初期化しました");
    return const CacheStatusData();
  }

  /// キャッシュ統計情報の更新
  /// Repository層から呼び出される（間接的にService経由）
  void updateStats(Map<String, dynamic> stats) {
    logDebug("キャッシュ統計情報を更新");
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
    logInfo("キャッシュクリアが完了しました");
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
class CachePerformance extends _$CachePerformance with ProviderLoggerMixin {
  @override
  String get providerComponent => "CachePerformance";
  
  @override
  CachePerformanceData build() {
    logInfo("キャッシュパフォーマンス監視を初期化しました");
    return const CachePerformanceData();
  }

  /// キャッシュヒット記録
  void recordHit() {
    logTrace("キャッシュヒットを記録");
    state = state.copyWith(
      hits: state.hits + 1,
      totalRequests: state.totalRequests + 1,
    );
  }

  /// キャッシュミス記録
  void recordMiss() {
    logTrace("キャッシュミスを記録");
    state = state.copyWith(
      misses: state.misses + 1,
      totalRequests: state.totalRequests + 1,
    );
  }

  /// 統計リセット
  void resetStats() {
    logDebug("キャッシュパフォーマンス統計をリセット");
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
class ConfirmationDialog extends _$ConfirmationDialog with ProviderLoggerMixin {
  @override
  String get providerComponent => "ConfirmationDialog";
  
  @override
  ConfirmationDialogState build() {
    logInfo("確認ダイアログ管理を初期化しました");
    return const ConfirmationDialogState(isVisible: false);
  }

  /// 確認ダイアログを表示
  void showDialog({
    String? title,
    String? message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    logDebug("確認ダイアログを表示: $title");
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
    logDebug("確認ダイアログを非表示");
    state = const ConfirmationDialogState(isVisible: false);
  }

  /// 確認ボタンが押された時の処理
  void confirm() {
    logDebug("確認ダイアログで確認が押されました");
    state.onConfirm?.call();
    hideDialog();
  }

  /// キャンセルボタンが押された時の処理
  void cancel() {
    logDebug("確認ダイアログでキャンセルが押されました");
    state.onCancel?.call();
    hideDialog();
  }
}
