// 🚧 互換レイヤ（暫定）
// features 層からの参照を core 経由に寄せるための一時的エクスポート。
// 最終的には features 側のロガー注入完了後に削除予定。

@Deprecated("Use LoggerContract via DI and loggerProvider")
// TODO(LoggingMigration): remove after verifying no usages remain by 2025-11-01.
export "../../infra/logging/logger.dart";
