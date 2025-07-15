import "../../../core/utils/logger_mixin.dart";
import "../../auth/models/user_model.dart";
import "../../auth/services/auth_service.dart";
import "../dto/business_hours_dto.dart";
import "../dto/operation_status_dto.dart";
import "../models/business_hours_model.dart";
import "../models/operation_status_model.dart";
import "../repositories/business_hours_repository.dart";
import "../repositories/operation_status_repository.dart";

/// 営業運営サービス
///
/// 営業時間と営業状態に関するビジネスロジックを提供します。
class BusinessOperationsService with LoggerMixin {
  BusinessOperationsService({
    required BusinessHoursRepository businessHoursRepository,
    required OperationStatusRepository operationStatusRepository,
    required AuthService authService,
  }) : _businessHoursRepository = businessHoursRepository,
       _operationStatusRepository = operationStatusRepository,
       _authService = authService;

  final BusinessHoursRepository _businessHoursRepository;
  final OperationStatusRepository _operationStatusRepository;
  final AuthService _authService;

  @override
  String get loggerComponent => "BusinessOperationsService";

  /// 現在の営業時間と状態を取得
  Future<OperationStatusModel> getCurrentOperationStatus() async {
    try {
      logInfo("Getting current operation status");

      final UserModel? currentUser = await _authService.getCurrentUser();
      final String? userId = currentUser?.id;

      // 営業時間設定を取得
      BusinessHoursModel? businessHours = await _businessHoursRepository.getCurrentBusinessHours(
        userId: userId,
      );

      // データがない場合はデフォルト値を作成
      businessHours ??= await _createDefaultBusinessHours(userId);

      // 営業状態を取得
      OperationStatusModel? operationStatus = await _operationStatusRepository
          .getCurrentOperationStatus(userId: userId);

      if (operationStatus == null) {
        // 営業状態が存在しない場合は自動状態で作成
        final bool shouldBeOpen = businessHours.isWithinOperatingHours();
        operationStatus = OperationStatusModel(
          userId: userId,
          isCurrentlyOpen: shouldBeOpen,
          businessHours: businessHours,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        operationStatus = await _operationStatusRepository.upsertOperationStatus(operationStatus);
      } else {
        // 営業時間が更新されている可能性があるので最新の営業時間で更新
        operationStatus = operationStatus.copyWith(businessHours: businessHours);

        // 手動オーバーライドでない場合は自動更新
        if (!operationStatus.manualOverride) {
          operationStatus = operationStatus.updateAutomaticStatus();
          if (operationStatus.lastStatusChange != null) {
            await _operationStatusRepository.upsertOperationStatus(operationStatus);
          }
        }
      }

      logInfo("Successfully retrieved operation status");
      return operationStatus;
    } catch (e, stackTrace) {
      logError("Failed to get current operation status", e, stackTrace);
      // エラーが発生した場合はデフォルト値を返す
      return OperationStatusModel(
        isCurrentlyOpen: false,
        businessHours: _getDefaultBusinessHours(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// 今日の営業時間を取得
  Future<BusinessHoursModel> getTodayBusinessHours() async {
    try {
      final UserModel? currentUser = await _authService.getCurrentUser();
      final String? userId = currentUser?.id;

      final DateTime now = DateTime.now();
      final int dayOfWeek = now.weekday % 7; // 0:日曜日、1:月曜日、...、6:土曜日

      // 曜日別の営業時間を取得
      final BusinessHoursModel? daySpecificHours = await _businessHoursRepository
          .getBusinessHoursByDay(dayOfWeek, userId: userId);

      if (daySpecificHours != null) {
        return daySpecificHours;
      }

      // 曜日別設定がない場合は現在の営業時間を返す
      final BusinessHoursModel? defaultHours = await _businessHoursRepository
          .getCurrentBusinessHours(userId: userId);

      return defaultHours ?? await _createDefaultBusinessHours(userId);
    } catch (e, stackTrace) {
      logError("Failed to get today's business hours", e, stackTrace);
      return _getDefaultBusinessHours();
    }
  }

  /// 営業状態を手動で切り替え
  Future<OperationStatusModel> toggleOperationStatus({String? reason}) async {
    try {
      logInfo("Toggling operation status");

      final OperationStatusModel current = await getCurrentOperationStatus();
      final OperationStatusModel toggled = current.toggleManualOverride(
        status: !current.isCurrentlyOpen,
        reason: reason,
      );

      final OperationStatusModel result = await _operationStatusRepository.upsertOperationStatus(
        toggled,
      );
      logInfo("Successfully toggled operation status to ${result.isCurrentlyOpen}");

      return result;
    } catch (e, stackTrace) {
      logError("Failed to toggle operation status", e, stackTrace);
      rethrow;
    }
  }

  /// 手動オーバーライドを解除
  Future<OperationStatusModel> clearManualOverride() async {
    try {
      logInfo("Clearing manual override");

      final OperationStatusModel current = await getCurrentOperationStatus();
      final OperationStatusModel cleared = current.clearManualOverride();

      final OperationStatusModel result = await _operationStatusRepository.upsertOperationStatus(
        cleared,
      );
      logInfo("Successfully cleared manual override");

      return result;
    } catch (e, stackTrace) {
      logError("Failed to clear manual override", e, stackTrace);
      rethrow;
    }
  }

  /// 営業時間を更新
  Future<BusinessHoursModel> updateBusinessHours(BusinessHoursDto businessHoursDto) async {
    try {
      logInfo("Updating business hours");

      final UserModel? currentUser = await _authService.getCurrentUser();
      final BusinessHoursModel businessHours = businessHoursDto.toModel(userId: currentUser?.id);

      // 妥当性をチェック
      final Map<String, dynamic> validation = await _businessHoursRepository.validateBusinessHours(
        businessHoursDto,
      );
      if (!(validation["is_valid"] as bool)) {
        throw Exception("Invalid business hours: ${validation['errors']}");
      }

      final BusinessHoursModel result = await _businessHoursRepository.upsertBusinessHours(
        businessHours,
      );
      logInfo("Successfully updated business hours");

      // 営業状態も自動更新
      await _updateOperationStatusAfterBusinessHoursChange(result);

      return result;
    } catch (e, stackTrace) {
      logError("Failed to update business hours", e, stackTrace);
      rethrow;
    }
  }

  /// 曜日別営業時間を一括更新
  Future<Map<int, BusinessHoursModel>> updateWeeklyBusinessHours(
    Map<int, BusinessHoursDto> weeklyHours,
  ) async {
    try {
      logInfo("Updating weekly business hours");

      final UserModel? currentUser = await _authService.getCurrentUser();
      if (currentUser?.id == null) {
        throw Exception("User not authenticated");
      }

      final List<BusinessHoursModel> results = await _businessHoursRepository
          .bulkUpdateDayBusinessHours(weeklyHours, currentUser!.id!);

      final Map<int, BusinessHoursModel> resultMap = <int, BusinessHoursModel>{};
      for (final BusinessHoursModel hours in results) {
        if (hours.dayOfWeek != null) {
          resultMap[hours.dayOfWeek!] = hours;
        }
      }

      logInfo("Successfully updated weekly business hours");
      return resultMap;
    } catch (e, stackTrace) {
      logError("Failed to update weekly business hours", e, stackTrace);
      rethrow;
    }
  }

  /// 全曜日の営業時間を取得
  Future<Map<int, BusinessHoursModel>> getWeeklyBusinessHours() async {
    try {
      final UserModel? currentUser = await _authService.getCurrentUser();
      final Map<int, BusinessHoursModel> weeklyHours = await _businessHoursRepository
          .getAllDayBusinessHours(userId: currentUser?.id);

      // 未設定の曜日はデフォルト値を設定
      final BusinessHoursModel defaultHours = await getTodayBusinessHours();
      for (int day = 0; day < 7; day++) {
        weeklyHours[day] ??= defaultHours.copyWith(dayOfWeek: day);
      }

      return weeklyHours;
    } catch (e, stackTrace) {
      logError("Failed to get weekly business hours", e, stackTrace);
      rethrow;
    }
  }

  /// 臨時休業を設定
  Future<OperationStatusModel> setTemporaryClose({
    required DateTime reopenTime,
    String? reason,
  }) async {
    try {
      logInfo("Setting temporary close until ${reopenTime.toIso8601String()}");

      final UserModel? currentUser = await _authService.getCurrentUser();
      final OperationStatusDto dto = OperationStatusDto.temporaryClose(
        reopenTime: reopenTime,
        reason: reason,
        userId: currentUser?.id,
      );

      final OperationStatusModel current = await getCurrentOperationStatus();
      final OperationStatusModel tempClose = dto.toModel(
        id: current.id,
        userId: currentUser?.id,
        businessHours: current.businessHours,
      );

      final OperationStatusModel result = await _operationStatusRepository.upsertOperationStatus(
        tempClose,
      );
      logInfo("Successfully set temporary close");

      return result;
    } catch (e, stackTrace) {
      logError("Failed to set temporary close", e, stackTrace);
      rethrow;
    }
  }

  /// 緊急営業を設定
  Future<OperationStatusModel> setEmergencyOpen({String? reason}) async {
    try {
      logInfo("Setting emergency open");

      final UserModel? currentUser = await _authService.getCurrentUser();
      final OperationStatusDto dto = OperationStatusDto.emergencyOpen(
        reason: reason,
        userId: currentUser?.id,
      );

      final OperationStatusModel current = await getCurrentOperationStatus();
      final OperationStatusModel emergencyOpen = dto.toModel(
        id: current.id,
        userId: currentUser?.id,
        businessHours: current.businessHours,
      );

      final OperationStatusModel result = await _operationStatusRepository.upsertOperationStatus(
        emergencyOpen,
      );
      logInfo("Successfully set emergency open");

      return result;
    } catch (e, stackTrace) {
      logError("Failed to set emergency open", e, stackTrace);
      rethrow;
    }
  }

  /// 営業状態の詳細情報を取得
  Future<Map<String, dynamic>> getOperationStatusInfo() async {
    try {
      final OperationStatusModel status = await getCurrentOperationStatus();

      return <String, dynamic>{
        "status": status,
        "display_status": status.displayStatus,
        "display_hours": status.displayHours,
        "status_color": status.statusColor,
        "minutes_until_close": status.minutesUntilClose,
        "minutes_until_open": status.minutesUntilOpen,
        "detailed_description": status.detailedStatusDescription,
        "can_toggle": true,
        "is_manual_override": status.manualOverride,
        "last_change": status.lastStatusChange?.toIso8601String(),
      };
    } catch (e, stackTrace) {
      logError("Failed to get operation status info", e, stackTrace);
      rethrow;
    }
  }

  /// 営業状態の統計を取得
  Future<Map<String, dynamic>> getOperationStatistics({int days = 30}) async {
    try {
      final UserModel? currentUser = await _authService.getCurrentUser();
      if (currentUser?.id == null) {
        throw Exception("User not authenticated");
      }

      return await _operationStatusRepository.getOperationStatistics(currentUser!.id!, days: days);
    } catch (e, stackTrace) {
      logError("Failed to get operation statistics", e, stackTrace);
      rethrow;
    }
  }

  /// 営業状態の整合性をチェック
  Future<Map<String, dynamic>> validateOperationStatus() async {
    try {
      final UserModel? currentUser = await _authService.getCurrentUser();
      if (currentUser?.id == null) {
        throw Exception("User not authenticated");
      }

      return await _operationStatusRepository.validateOperationStatus(currentUser!.id!);
    } catch (e, stackTrace) {
      logError("Failed to validate operation status", e, stackTrace);
      rethrow;
    }
  }

  /// 営業時間変更後の営業状態を自動更新
  Future<void> _updateOperationStatusAfterBusinessHoursChange(BusinessHoursModel newHours) async {
    try {
      final OperationStatusModel? current = await _operationStatusRepository
          .getCurrentOperationStatus(userId: newHours.userId);

      if (current != null && !current.manualOverride) {
        final bool shouldBeOpen = newHours.isWithinOperatingHours();
        if (shouldBeOpen != current.isCurrentlyOpen) {
          final OperationStatusModel updated = current.copyWith(
            isCurrentlyOpen: shouldBeOpen,
            businessHours: newHours,
            lastStatusChange: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _operationStatusRepository.upsertOperationStatus(updated);
        }
      }
    } catch (e, stackTrace) {
      logError("Failed to update operation status after business hours change", e, stackTrace);
    }
  }

  /// デフォルトの営業時間を作成してデータベースに保存
  Future<BusinessHoursModel> _createDefaultBusinessHours(String? userId) async {
    final BusinessHoursModel defaultHours = _getDefaultBusinessHours().copyWith(userId: userId);
    return _businessHoursRepository.upsertBusinessHours(defaultHours);
  }

  /// デフォルトの営業時間を取得
  BusinessHoursModel _getDefaultBusinessHours() => BusinessHoursModel(
    openTime: "11:00",
    closeTime: "22:00",
    isOpen: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// 定期的な営業状態の自動更新を実行
  Future<void> performScheduledStatusUpdate() async {
    try {
      logInfo("Performing scheduled status update");

      final UserModel? currentUser = await _authService.getCurrentUser();
      if (currentUser?.id == null) {
        return;
      }

      final OperationStatusModel current = await getCurrentOperationStatus();

      // 手動オーバーライドでない場合のみ自動更新
      if (!current.manualOverride) {
        final BusinessHoursModel todayHours = await getTodayBusinessHours();
        final bool shouldBeOpen = todayHours.isWithinOperatingHours();

        if (shouldBeOpen != current.isCurrentlyOpen) {
          final OperationStatusModel updated = current.copyWith(
            isCurrentlyOpen: shouldBeOpen,
            businessHours: todayHours,
            lastStatusChange: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _operationStatusRepository.upsertOperationStatus(updated);
          logInfo("Status automatically updated to ${shouldBeOpen ? 'open' : 'closed'}");
        }
      }

      // 予定された再開時刻の処理
      if (current.estimatedReopenTime != null &&
          current.estimatedReopenTime!.isBefore(DateTime.now())) {
        await clearManualOverride();
        logInfo("Cleared expired manual override");
      }
    } catch (e, stackTrace) {
      logError("Failed to perform scheduled status update", e, stackTrace);
    }
  }
}
