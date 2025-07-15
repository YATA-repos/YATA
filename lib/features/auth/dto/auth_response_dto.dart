import "package:json_annotation/json_annotation.dart";

import "../models/user_model.dart";

part "auth_response_dto.g.dart";

/// 認証レスポンスDTO
///
/// 認証関連のAPIレスポンスに使用するデータ転送オブジェクト。
@JsonSerializable()
class AuthResponseDto {
  const AuthResponseDto({
    this.success = false,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.expiresIn,
    this.tokenType,
    this.message,
    this.error,
  });

  /// 成功レスポンス用のファクトリーコンストラクタ
  factory AuthResponseDto.success({
    required UserModel user,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    int? expiresIn,
    String? tokenType,
    String? message,
  }) => AuthResponseDto(
    success: true,
    user: user,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
    expiresIn: expiresIn,
    tokenType: tokenType ?? "Bearer",
    message: message ?? "認証に成功しました",
  );

  /// エラーレスポンス用のファクトリーコンストラクタ
  factory AuthResponseDto.error({required String error, String? message}) =>
      AuthResponseDto(error: error, message: message ?? "認証に失敗しました");

  /// セッション情報レスポンス用のファクトリーコンストラクタ
  factory AuthResponseDto.session({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    int? expiresIn,
    String? tokenType,
  }) => AuthResponseDto(
    success: true,
    user: user,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
    expiresIn: expiresIn,
    tokenType: tokenType ?? "Bearer",
    message: "セッション情報を取得しました",
  );

  /// ログアウト成功レスポンス用のファクトリーコンストラクタ
  factory AuthResponseDto.signOut() => const AuthResponseDto(success: true, message: "ログアウトしました");

  /// JSONからAuthResponseDtoを作成
  factory AuthResponseDto.fromJson(Map<String, dynamic> json) => _$AuthResponseDtoFromJson(json);

  /// 認証が成功したかどうか
  final bool success;

  /// ユーザー情報
  final UserModel? user;

  /// アクセストークン
  final String? accessToken;

  /// リフレッシュトークン
  final String? refreshToken;

  /// トークン有効期限
  final DateTime? expiresAt;

  /// トークン有効期間（秒）
  final int? expiresIn;

  /// トークンタイプ（通常は"Bearer"）
  final String? tokenType;

  /// レスポンスメッセージ
  final String? message;

  /// エラーメッセージ
  final String? error;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$AuthResponseDtoToJson(this);

  /// セッションが有効かどうか
  bool get hasValidSession =>
      success &&
      user != null &&
      accessToken != null &&
      expiresAt != null &&
      DateTime.now().isBefore(expiresAt!);

  /// トークンがまもなく期限切れかどうか（10分以内）
  bool get tokenNeedsRefresh {
    if (expiresAt == null) {
      return false;
    }
    final int timeToExpiry = expiresAt!.difference(DateTime.now()).inSeconds;
    return timeToExpiry < 600; // 10分 = 600秒
  }

  @override
  String toString() =>
      "AuthResponseDto(success: $success, user: ${user?.email}, message: $message, error: $error)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthResponseDto &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          user == other.user &&
          accessToken == other.accessToken &&
          message == other.message &&
          error == other.error;

  @override
  int get hashCode => Object.hash(success, user, accessToken, message, error);
}
