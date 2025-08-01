/// 全プロバイダーの統一エクスポート
/// アプリケーション全体で使用するプロバイダーを一箇所から提供
library;

// プロバイダーエクスポート（アルファベット順）
export "cache_providers.dart" hide CacheStatus, cacheStatusProvider;
export "common_providers.dart";
export "development_providers.dart" if (dart.library.developer) "development_providers.dart";
export "realtime_providers.dart";
export "system_providers.dart";

/// プロバイダー使用ガイドライン
/// 
/// **UI状態**: common_providers.dart
/// - GlobalError, GlobalLoading, SuccessMessage等
/// 
/// **システム**: system_providers.dart  
/// - SystemInitialization, ApplicationHealth等
/// 
/// **キャッシュ**: cache_providers.dart
/// - CacheStatus, CachePerformance, GlobalCacheControl等
/// 
/// **リアルタイム**: realtime_providers.dart
/// - GlobalRealtimeControl, RealtimeConnectionStats等
/// 
/// **開発用**: development_providers.dart
/// - DebugModeControl, PerformanceMonitor等