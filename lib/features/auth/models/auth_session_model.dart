import "package:json_annotation/json_annotation.dart";

import "../../../core/base/base_model.dart";

part "auth_session_model.g.dart";

/// 認証セッションモデル
///
/// ユーザーのログインセッション情報を管理します。
@JsonSerializable()
class AuthSessionModel extends BaseModel {
  AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresAt,
    super.id,
    super.userId,
    this.expiresIn,
    this.providerToken,
    this.providerRefreshToken,
    this.createdAt,
    this.updatedAt,
  });

  /// JSONからAuthSessionModelを作成
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) => _$AuthSessionModelFromJson(json);

  @override
  String get tableName => "auth_sessions";

  /// アクセストークン
  final String accessToken;

  /// リフレッシュトークン
  final String refreshToken;

  /// トークンタイプ（通常は "Bearer"）
  final String tokenType;

  /// トークン有効期限
  final DateTime expiresAt;

  /// トークン有効期間（秒）
  final int? expiresIn;

  /// プロバイダートークン（OAuth認証時）
  final String? providerToken;

  /// プロバイダーリフレッシュトークン（OAuth認証時）
  final String? providerRefreshToken;

  /// 作成日時
  final DateTime? createdAt;

  /// 更新日時
  final DateTime? updatedAt;

  @override
  Map<String, dynamic> toJson() => _$AuthSessionModelToJson(this);

  /// セッションが有効かどうか
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// セッションの期限切れまでの時間（秒）
  int get timeToExpiry => expiresAt.difference(DateTime.now()).inSeconds;

  /// リフレッシュが必要かどうか（期限の10分前）
  bool get needsRefresh => timeToExpiry < 600;

  /// コピーメソッド
  AuthSessionModel copyWith({
    String? id,
    String? userId,
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
    int? expiresIn,
    String? providerToken,
    String? providerRefreshToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AuthSessionModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    tokenType: tokenType ?? this.tokenType,
    expiresAt: expiresAt ?? this.expiresAt,
    expiresIn: expiresIn ?? this.expiresIn,
    providerToken: providerToken ?? this.providerToken,
    providerRefreshToken: providerRefreshToken ?? this.providerRefreshToken,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() =>
      "AuthSessionModel(id: $id, userId: $userId, expiresAt: $expiresAt, isValid: $isValid)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSessionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          accessToken == other.accessToken &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(id, userId, accessToken, expiresAt);
}
