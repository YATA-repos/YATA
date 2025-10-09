import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/contracts/auth/auth_repository_contract.dart" as auth_contract;
import "../../core/contracts/logging/logger.dart" as log_contract;
import "../../features/auth/dto/auth_response.dart" as auth_dto;
import "../../features/auth/models/user_profile.dart";
import "provider.dart";

/// 本番環境での依存差し替え用雛形。
///
/// 例: 実際のロガーをプラットフォーム固有実装に入れ替える。
List<Override> buildProdOverrides({
  log_contract.LoggerContract? logger,
  auth_contract.AuthRepositoryContract<UserProfile, auth_dto.AuthResponse>? authRepository,
  Iterable<Override> extra = const <Override>[],
}) {
  final List<Override> overrides = <Override>[
    if (logger != null) loggerProvider.overrideWithValue(logger),
    if (authRepository != null) authRepositoryProvider.overrideWithValue(authRepository),
  ];

  // * 環境依存の外部サービスを差し替える場合は `extra` に追記する。
  overrides.addAll(extra);
  return overrides;
}
