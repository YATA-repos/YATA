import "../../../core/base/base_repository.dart";
import "../../../core/constants/log_enums/repository.dart";
import "../../../core/constants/query_types.dart";
import "../models/user_model.dart";

/// ユーザーリポジトリ
///
/// ユーザー情報のCRUD操作を提供します。
class UserRepository extends BaseRepository<UserModel, String> {
  UserRepository() : super(tableName: "users");

  @override
  String get tableName => "users";

  @override
  UserModel fromJson(Map<String, dynamic> json) => UserModel.fromJson(json);

  /// メールアドレスでユーザーを検索
  Future<UserModel?> findByEmail(String email) async {
    try {
      final List<UserModel> users = await find(
        filters: <QueryFilter>[QueryConditionBuilder.eq("email", email)],
        limit: 1,
      );

      return users.isNotEmpty ? users.first : null;
    } catch (e, stackTrace) {
      logError("findByEmail: Failed to find user by email", e, stackTrace);
      rethrow;
    }
  }

  /// ロールでユーザーを検索
  Future<List<UserModel>> findByRole(UserRole role) async {
    try {
      return await find(filters: <QueryFilter>[QueryConditionBuilder.eq("role", role.name)]);
    } catch (e, stackTrace) {
      logError("findByRole: Failed to find users by role", e, stackTrace);
      rethrow;
    }
  }

  /// アクティブなユーザーを取得（最近ログインしたユーザー）
  Future<List<UserModel>> getActiveUsers({
    int daysBack = 30,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

      return await find(
        filters: <QueryFilter>[
          QueryConditionBuilder.isNotNull("last_sign_in_at"),
          QueryConditionBuilder.gte("last_sign_in_at", cutoffDate.toIso8601String()),
        ],
        orderBy: <OrderByCondition>[OrderByCondition(column: "last_sign_in_at", ascending: false)],
        limit: limit,
        offset: offset,
      );
    } catch (e, stackTrace) {
      logError("getActiveUsers: Failed to get active users", e, stackTrace);
      rethrow;
    }
  }

  /// メール認証済みユーザーを取得
  Future<List<UserModel>> getVerifiedUsers({int limit = 100, int offset = 0}) async {
    try {
      return await find(
        filters: <QueryFilter>[QueryConditionBuilder.eq("email_verified", true)],
        orderBy: <OrderByCondition>[OrderByCondition(column: "created_at", ascending: false)],
        limit: limit,
        offset: offset,
      );
    } catch (e, stackTrace) {
      logError("getVerifiedUsers: Failed to get verified users", e, stackTrace);
      rethrow;
    }
  }

  /// ユーザーの最終ログイン時刻を更新
  Future<void> updateLastSignIn(String userId) async {
    try {
      await updateById(userId, <String, dynamic>{
        "last_sign_in_at": DateTime.now().toIso8601String(),
        "updated_at": DateTime.now().toIso8601String(),
      });

      logDebug("updateLastSignIn: Updated last sign in for user: $userId");
    } catch (e, stackTrace) {
      logError("updateLastSignIn: Failed to update last sign in", e, stackTrace);
      rethrow;
    }
  }

  /// ユーザープロフィールを更新
  Future<UserModel> updateProfile(
    String userId, {
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final Map<String, dynamic> updates = <String, dynamic>{
        "updated_at": DateTime.now().toIso8601String(),
      };

      if (displayName != null) {
        updates["display_name"] = displayName;
      }
      if (avatarUrl != null) {
        updates["avatar_url"] = avatarUrl;
      }
      if (phoneNumber != null) {
        updates["phone_number"] = phoneNumber;
      }
      if (metadata != null) {
        updates["metadata"] = metadata;
      }

      await updateById(userId, updates);

      // 更新されたユーザー情報を取得
      final UserModel? updatedUser = await getById(userId);
      if (updatedUser == null) {
        throw RepositoryException(
          RepositoryError.recordNotFound,
          params: <String, String>{"id": userId},
        );
      }

      logDebug("updateProfile: Updated profile for user: $userId");
      return updatedUser;
    } catch (e, stackTrace) {
      logError("updateProfile: Failed to update user profile", e, stackTrace);
      rethrow;
    }
  }

  /// 管理者権限を持つユーザーかどうかを確認
  Future<bool> isAdmin(String userId) async {
    try {
      final UserModel? user = await getById(userId);
      return user?.role.isAdmin ?? false;
    } catch (e, stackTrace) {
      logError("isAdmin: Failed to check admin status", e, stackTrace);
      return false;
    }
  }

  /// スタッフ権限を持つユーザーかどうかを確認
  Future<bool> isStaff(String userId) async {
    try {
      final UserModel? user = await getById(userId);
      return user?.role.isStaff ?? false;
    } catch (e, stackTrace) {
      logError("isStaff: Failed to check staff status", e, stackTrace);
      return false;
    }
  }
}
