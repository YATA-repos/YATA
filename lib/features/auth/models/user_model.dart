import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base_model.dart";

part "user_model.g.dart";

/// ユーザーモデル
///
/// 認証されたユーザーの情報を管理します。
@JsonSerializable()
class UserModel extends BaseModel {
  UserModel({
    required this.email,
    super.id,
    super.userId,
    this.displayName,
    this.avatarUrl,
    this.phoneNumber,
    this.emailVerified = false,
    this.role = UserRole.manager,
    this.lastSignInAt,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// JSONからUserModelを作成
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  @override
  String get tableName => "users";

  /// メールアドレス
  final String email;

  /// 表示名
  final String? displayName;

  /// アバターURL
  final String? avatarUrl;

  /// 電話番号
  final String? phoneNumber;

  /// メール認証済みフラグ
  final bool emailVerified;

  /// ユーザーロール
  final UserRole role;

  /// 最後のサインイン日時
  final DateTime? lastSignInAt;

  /// 作成日時
  final DateTime? createdAt;

  /// 更新日時
  final DateTime? updatedAt;

  /// メタデータ（任意の追加情報）
  final Map<String, dynamic>? metadata;

  @override
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// コピーメソッド
  UserModel copyWith({
    String? id,
    String? userId,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
    bool? emailVerified,
    UserRole? role,
    DateTime? lastSignInAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) => UserModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    emailVerified: emailVerified ?? this.emailVerified,
    role: role ?? this.role,
    lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    metadata: metadata ?? this.metadata,
  );

  @override
  String toString() => "UserModel(id: $id, email: $email, displayName: $displayName, role: $role)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, email, displayName, role);
}

/// ユーザーロール列挙型
@JsonEnum()
enum UserRole {
  /// システム管理者
  @JsonValue("admin")
  admin,

  /// 店舗管理者
  @JsonValue("manager")
  manager,

  /// スタッフ
  @JsonValue("staff")
  staff,

  /// 閲覧者
  @JsonValue("viewer")
  viewer,
}

/// UserRole拡張メソッド
extension UserRoleExtension on UserRole {
  /// ロール名を取得
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return "システム管理者";
      case UserRole.manager:
        return "店舗管理者";
      case UserRole.staff:
        return "スタッフ";
      case UserRole.viewer:
        return "閲覧者";
    }
  }

  /// 権限レベル（数値が高いほど権限が強い）
  int get level {
    switch (this) {
      case UserRole.admin:
        return 100;
      case UserRole.manager:
        return 80;
      case UserRole.staff:
        return 60;
      case UserRole.viewer:
        return 40;
    }
  }

  /// 指定されたロールにアクセス可能かどうか
  bool canAccess(UserRole requiredRole) => level >= requiredRole.level;

  /// 文字列値からUserRoleを取得
  static UserRole? fromValue(String value) {
    try {
      return UserRole.values.firstWhere((UserRole role) {
        switch (role) {
          case UserRole.admin:
            return value == "admin";
          case UserRole.manager:
            return value == "manager";
          case UserRole.staff:
            return value == "staff";
          case UserRole.viewer:
            return value == "viewer";
        }
      });
    } catch (e) {
      return null;
    }
  }

  /// JSON形式での表現
  String toJson() {
    switch (this) {
      case UserRole.admin:
        return "admin";
      case UserRole.manager:
        return "manager";
      case UserRole.staff:
        return "staff";
      case UserRole.viewer:
        return "viewer";
    }
  }

  /// JSON形式からの復元
  static UserRole fromJson(String json) {
    final UserRole? role = fromValue(json);
    if (role == null) {
      throw ArgumentError("Invalid UserRole value: $json");
    }
    return role;
  }

  /// 管理者権限があるかどうか
  bool get isAdmin => this == UserRole.admin;

  /// 管理権限があるかどうか（管理者または店舗管理者）
  bool get isManager => this == UserRole.admin || this == UserRole.manager;

  /// スタッフ権限があるかどうか
  bool get isStaff => canAccess(UserRole.staff);
}
