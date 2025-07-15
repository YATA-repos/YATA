import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../auth/presentation/providers/auth_provider.dart";
import "../../../auth/repositories/user_repository.dart";
import "../../../auth/services/auth_service.dart";
import "../../dto/business_hours_dto.dart";
import "../../models/business_hours_model.dart";
import "../../models/operation_status_model.dart";
import "../../repositories/business_hours_repository.dart";
import "../../repositories/operation_status_repository.dart";
import "../../services/business_operations_service.dart";

/// 営業時間リポジトリプロバイダー
final Provider<BusinessHoursRepository> businessHoursRepositoryProvider =
    Provider<BusinessHoursRepository>(
      (Ref<BusinessHoursRepository> ref) => BusinessHoursRepository(),
    );

/// 営業状態リポジトリプロバイダー
final Provider<OperationStatusRepository> operationStatusRepositoryProvider =
    Provider<OperationStatusRepository>(
      (Ref<OperationStatusRepository> ref) => OperationStatusRepository(),
    );

/// 営業運営サービスプロバイダー
final Provider<BusinessOperationsService> businessOperationsServiceProvider =
    Provider<BusinessOperationsService>(
      (Ref<BusinessOperationsService> ref) => BusinessOperationsService(
        businessHoursRepository: ref.read(businessHoursRepositoryProvider),
        operationStatusRepository: ref.read(operationStatusRepositoryProvider),
        authService: AuthService(
          supabaseAuthService: ref.read(authServiceProvider),
          userRepository: UserRepository(),
        ),
      ),
    );

/// 現在の営業状態プロバイダー
final FutureProvider<OperationStatusModel> operationStatusProvider =
    FutureProvider<OperationStatusModel>((Ref ref) async {
      final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
      return service.getCurrentOperationStatus();
    });

/// 営業時間プロバイダー
final FutureProvider<BusinessHoursModel> businessHoursProvider = FutureProvider<BusinessHoursModel>(
  (Ref ref) async {
    final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
    return service.getTodayBusinessHours();
  },
);

/// 今日の営業時間プロバイダー
final FutureProvider<BusinessHoursModel> todayBusinessHoursProvider =
    FutureProvider<BusinessHoursModel>((Ref ref) async {
      final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
      return service.getTodayBusinessHours();
    });

/// 週間営業時間プロバイダー
final FutureProvider<Map<int, BusinessHoursModel>> weeklyBusinessHoursProvider =
    FutureProvider<Map<int, BusinessHoursModel>>((Ref ref) async {
      final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
      return service.getWeeklyBusinessHours();
    });

/// 営業状態詳細情報プロバイダー
final FutureProvider<Map<String, dynamic>> operationStatusInfoProvider =
    FutureProvider<Map<String, dynamic>>((Ref ref) async {
      final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
      return service.getOperationStatusInfo();
    });

/// 営業統計プロバイダー
final FutureProviderFamily<Map<String, dynamic>, int> operationStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((Ref ref, int days) async {
      final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
      return service.getOperationStatistics(days: days);
    });

/// 営業状態検証プロバイダー
final FutureProvider<Map<String, dynamic>> operationStatusValidationProvider =
    FutureProvider<Map<String, dynamic>>((Ref ref) async {
      final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
      return service.validateOperationStatus();
    });

/// 営業状態切り替え中フラグ
final StateProvider<bool> isToggleOperationStatusProvider = StateProvider<bool>(
  (Ref<bool> ref) => false,
);

/// 営業時間更新中フラグ
final StateProvider<bool> isUpdatingBusinessHoursProvider = StateProvider<bool>(
  (Ref<bool> ref) => false,
);

/// 選択中の曜日（営業時間設定用）
final StateProvider<int?> selectedDayOfWeekProvider = StateProvider<int?>((Ref<int?> ref) => null);

/// 営業時間編集モード
final StateProvider<bool> businessHoursEditModeProvider = StateProvider<bool>(
  (Ref<bool> ref) => false,
);

/// 営業状態を手動で切り替えるメソッド
final Provider<Future<OperationStatusModel> Function({String? reason})>
toggleOperationStatusProvider = Provider<Future<OperationStatusModel> Function({String? reason})>(
  (Ref<Future<OperationStatusModel> Function({String? reason})> ref) => ({String? reason}) async {
    ref.read(isToggleOperationStatusProvider.notifier).state = true;
    try {
      final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
      final OperationStatusModel result = await service.toggleOperationStatus(reason: reason);

      // 関連するプロバイダーを更新
      ref
        ..invalidate(operationStatusProvider)
        ..invalidate(operationStatusInfoProvider);

      return result;
    } finally {
      ref.read(isToggleOperationStatusProvider.notifier).state = false;
    }
  },
);

/// 手動オーバーライドを解除するメソッド
final Provider<Future<OperationStatusModel> Function()> clearManualOverrideProvider =
    Provider<Future<OperationStatusModel> Function()>(
      (Ref<Future<OperationStatusModel> Function()> ref) => () async {
        final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
        final OperationStatusModel result = await service.clearManualOverride();

        // 関連するプロバイダーを更新
        ref
          ..invalidate(operationStatusProvider)
          ..invalidate(operationStatusInfoProvider);

        return result;
      },
    );

/// 営業時間を更新するメソッド
final Provider<Future<BusinessHoursModel> Function(BusinessHoursDto p1)>
updateBusinessHoursProvider = Provider<Future<BusinessHoursModel> Function(BusinessHoursDto)>(
  (Ref<Future<BusinessHoursModel> Function(BusinessHoursDto p1)> ref) =>
      (BusinessHoursDto dto) async {
        ref.read(isUpdatingBusinessHoursProvider.notifier).state = true;
        try {
          final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
          final BusinessHoursModel result = await service.updateBusinessHours(dto);

          // 関連するプロバイダーを更新
          ref
            ..invalidate(todayBusinessHoursProvider)
            ..invalidate(weeklyBusinessHoursProvider)
            ..invalidate(operationStatusProvider);

          return result;
        } finally {
          ref.read(isUpdatingBusinessHoursProvider.notifier).state = false;
        }
      },
);

/// 週間営業時間を一括更新するメソッド
final Provider<Future<Map<int, BusinessHoursModel>> Function(Map<int, BusinessHoursDto> p1)>
updateWeeklyBusinessHoursProvider =
    Provider<Future<Map<int, BusinessHoursModel>> Function(Map<int, BusinessHoursDto>)>(
      (Ref<Future<Map<int, BusinessHoursModel>> Function(Map<int, BusinessHoursDto> p1)> ref) =>
          (Map<int, BusinessHoursDto> weeklyHours) async {
            ref.read(isUpdatingBusinessHoursProvider.notifier).state = true;
            try {
              final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
              final Map<int, BusinessHoursModel> result = await service.updateWeeklyBusinessHours(
                weeklyHours,
              );

              // 関連するプロバイダーを更新
              ref
                ..invalidate(weeklyBusinessHoursProvider)
                ..invalidate(todayBusinessHoursProvider)
                ..invalidate(operationStatusProvider);

              return result;
            } finally {
              ref.read(isUpdatingBusinessHoursProvider.notifier).state = false;
            }
          },
    );

/// 臨時休業を設定するメソッド
final Provider<
  Future<OperationStatusModel> Function({required DateTime reopenTime, String? reason})
>
setTemporaryCloseProvider =
    Provider<Future<OperationStatusModel> Function({required DateTime reopenTime, String? reason})>(
      (
        Ref<Future<OperationStatusModel> Function({required DateTime reopenTime, String? reason})>
        ref,
      ) => ({required DateTime reopenTime, String? reason}) async {
        final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
        final OperationStatusModel result = await service.setTemporaryClose(
          reopenTime: reopenTime,
          reason: reason,
        );

        // 関連するプロバイダーを更新
        ref
          ..invalidate(operationStatusProvider)
          ..invalidate(operationStatusInfoProvider);

        return result;
      },
    );

/// 緊急営業を設定するメソッド
final Provider<Future<OperationStatusModel> Function({String? reason})> setEmergencyOpenProvider =
    Provider<Future<OperationStatusModel> Function({String? reason})>(
      (Ref<Future<OperationStatusModel> Function({String? reason})> ref) =>
          ({String? reason}) async {
            final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
            final OperationStatusModel result = await service.setEmergencyOpen(reason: reason);

            // 関連するプロバイダーを更新
            ref
              ..invalidate(operationStatusProvider)
              ..invalidate(operationStatusInfoProvider);

            return result;
          },
    );

/// 定期的な営業状態更新を実行するメソッド
final Provider<Future<void> Function()> performScheduledUpdateProvider =
    Provider<Future<void> Function()>(
      (Ref<Future<void> Function()> ref) => () async {
        final BusinessOperationsService service = ref.read(businessOperationsServiceProvider);
        await service.performScheduledStatusUpdate();

        // 関連するプロバイダーを更新
        ref
          ..invalidate(operationStatusProvider)
          ..invalidate(operationStatusInfoProvider);
      },
    );

/// 営業時間設定プロバイダー
final StateNotifierProvider<BusinessHoursSettingsNotifier, BusinessHoursSettings>
businessHoursSettingsProvider =
    StateNotifierProvider<BusinessHoursSettingsNotifier, BusinessHoursSettings>(
      (Ref ref) => BusinessHoursSettingsNotifier(),
    );

/// 営業時間設定クラス
class BusinessHoursSettings {
  const BusinessHoursSettings({
    this.defaultOpenTime = "11:00",
    this.defaultCloseTime = "22:00",
    this.enableDaySpecificHours = false,
    this.enableSpecialHours = false,
    this.autoUpdateOnTimeChange = true,
    this.notifyOnStatusChange = true,
  });

  final String defaultOpenTime;
  final String defaultCloseTime;
  final bool enableDaySpecificHours;
  final bool enableSpecialHours;
  final bool autoUpdateOnTimeChange;
  final bool notifyOnStatusChange;

  BusinessHoursSettings copyWith({
    String? defaultOpenTime,
    String? defaultCloseTime,
    bool? enableDaySpecificHours,
    bool? enableSpecialHours,
    bool? autoUpdateOnTimeChange,
    bool? notifyOnStatusChange,
  }) => BusinessHoursSettings(
    defaultOpenTime: defaultOpenTime ?? this.defaultOpenTime,
    defaultCloseTime: defaultCloseTime ?? this.defaultCloseTime,
    enableDaySpecificHours: enableDaySpecificHours ?? this.enableDaySpecificHours,
    enableSpecialHours: enableSpecialHours ?? this.enableSpecialHours,
    autoUpdateOnTimeChange: autoUpdateOnTimeChange ?? this.autoUpdateOnTimeChange,
    notifyOnStatusChange: notifyOnStatusChange ?? this.notifyOnStatusChange,
  );
}

/// 営業時間設定ノティファイアー
class BusinessHoursSettingsNotifier extends StateNotifier<BusinessHoursSettings> {
  BusinessHoursSettingsNotifier() : super(const BusinessHoursSettings());

  void updateDefaultOpenTime(String time) {
    state = state.copyWith(defaultOpenTime: time);
  }

  void updateDefaultCloseTime(String time) {
    state = state.copyWith(defaultCloseTime: time);
  }

  void updateEnableDaySpecificHours(bool enable) {
    state = state.copyWith(enableDaySpecificHours: enable);
  }

  void updateEnableSpecialHours(bool enable) {
    state = state.copyWith(enableSpecialHours: enable);
  }

  void updateAutoUpdateOnTimeChange(bool auto) {
    state = state.copyWith(autoUpdateOnTimeChange: auto);
  }

  void updateNotifyOnStatusChange(bool notify) {
    state = state.copyWith(notifyOnStatusChange: notify);
  }
}

/// 営業時間テンプレートプロバイダー
final Provider<List<BusinessHoursTemplate>> businessHoursTemplatesProvider =
    Provider<List<BusinessHoursTemplate>>(
      (Ref<List<BusinessHoursTemplate>> ref) => <BusinessHoursTemplate>[
        BusinessHoursTemplate(
          name: "標準営業",
          openTime: "11:00",
          closeTime: "22:00",
          description: "一般的なレストランの営業時間",
        ),
        BusinessHoursTemplate(
          name: "朝営業",
          openTime: "08:00",
          closeTime: "18:00",
          description: "朝食・ランチ中心の営業",
        ),
        BusinessHoursTemplate(
          name: "夜営業",
          openTime: "17:00",
          closeTime: "24:00",
          description: "ディナー・夜食中心の営業",
        ),
        BusinessHoursTemplate(
          name: "24時間",
          openTime: "00:00",
          closeTime: "23:59",
          description: "24時間営業",
        ),
      ],
    );

/// 営業時間テンプレートクラス
class BusinessHoursTemplate {
  const BusinessHoursTemplate({
    required this.name,
    required this.openTime,
    required this.closeTime,
    required this.description,
  });

  final String name;
  final String openTime;
  final String closeTime;
  final String description;

  BusinessHoursDto toDto({String? userId}) =>
      BusinessHoursDto(openTime: openTime, closeTime: closeTime, isOpen: true, userId: userId);
}
