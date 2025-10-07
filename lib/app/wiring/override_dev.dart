import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/contracts/auth/auth_repository_contract.dart" as auth_contract;
import "../../core/contracts/logging/logger.dart" as log_contract;
import "../../core/contracts/repositories/order/order_repository_contracts.dart" as order_contract;
import "../../features/auth/dto/auth_response.dart" as auth_dto;
import "../../features/auth/models/user_profile.dart";
import "../../features/order/models/order_model.dart";
import "provider.dart";

/// 開発環境用の ProviderScope オーバーライド雛形。
///
/// `main_dev.dart` などで `ProviderScope(overrides: buildDevOverrides(...))` のように使用する。
List<Override> buildDevOverrides({
  log_contract.LoggerContract? logger,
  auth_contract.AuthRepositoryContract<UserProfile, auth_dto.AuthResponse>? authRepository,
  order_contract.OrderRepositoryContract<Order>? orderRepository,
  Iterable<Override> extra = const <Override>[],
}) {
  final List<Override> overrides = <Override>[
    if (logger != null) loggerProvider.overrideWithValue(logger),
    if (authRepository != null) authRepositoryProvider.overrideWithValue(authRepository),
    if (orderRepository != null) orderRepositoryProvider.overrideWithValue(orderRepository),
  ];

  // * `extra` に Storybook やテスト専用のオーバーライドを渡して柔軟に拡張できる。
  overrides.addAll(extra);
  return overrides;
}
