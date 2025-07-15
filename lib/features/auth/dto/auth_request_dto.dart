import "package:json_annotation/json_annotation.dart";

part "auth_request_dto.g.dart";

/// 認証リクエストDTO
///
/// 認証関連のAPIリクエストに使用するデータ転送オブジェクト。
@JsonSerializable()
class AuthRequestDto {
  const AuthRequestDto({this.email, this.provider, this.redirectTo, this.scopes, this.queryParams});

  /// Googleログインリクエスト用のファクトリーコンストラクタ
  factory AuthRequestDto.googleSignIn({String? redirectTo, List<String>? scopes}) => AuthRequestDto(
    provider: "google",
    redirectTo: redirectTo,
    scopes: scopes ?? <String>["email", "profile"],
  );

  /// メールログインリクエスト用のファクトリーコンストラクタ
  factory AuthRequestDto.emailSignIn({required String email, String? redirectTo}) =>
      AuthRequestDto(email: email, redirectTo: redirectTo);

  /// JSONからAuthRequestDtoを作成
  factory AuthRequestDto.fromJson(Map<String, dynamic> json) => _$AuthRequestDtoFromJson(json);

  /// メールアドレス
  final String? email;

  /// 認証プロバイダー（google、github等）
  final String? provider;

  /// 認証後のリダイレクト先URL
  final String? redirectTo;

  /// 要求するスコープ
  final List<String>? scopes;

  /// 追加のクエリパラメータ
  final Map<String, String>? queryParams;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$AuthRequestDtoToJson(this);

  @override
  String toString() =>
      "AuthRequestDto(email: $email, provider: $provider, redirectTo: $redirectTo)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthRequestDto &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          provider == other.provider &&
          redirectTo == other.redirectTo;

  @override
  int get hashCode => Object.hash(email, provider, redirectTo);
}
