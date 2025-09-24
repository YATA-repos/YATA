import "package:json_annotation/json_annotation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../../core/base/base_model.dart";

part "user_profile.g.dart";

/// ユーザープロフィールモデル
///
/// Supabase認証で取得したユーザー情報を管理します。
/// Google OAuthからの情報も含みます。
@JsonSerializable()
class UserProfile extends BaseModel {
  UserProfile({
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.provider,
    this.providerId,
    this.emailVerified = false,
    this.createdAt,
    this.updatedAt,
    this.lastSignInAt,
    this.metadata,
    super.id,
    super.userId, // 注意: userIdはプロフィール自体のユーザーID
  });

  /// JSONからインスタンスを作成
  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

  /// Supabase Userオブジェクトから作成
  factory UserProfile.fromSupabaseUser(User user) {
    final Map<String, dynamic> appMetadata = user.appMetadata;
    final Map<String, dynamic> userMetadata = user.userMetadata ?? <String, dynamic>{};

    return UserProfile(
      id: user.id,
      userId: user.id, // Supabaseの場合、userIdは自分自身のID
      email: user.email ?? "",
      displayName: _extractDisplayName(appMetadata, userMetadata),
      avatarUrl: _extractAvatarUrl(appMetadata, userMetadata),
      provider: _extractProvider(user),
      providerId: _extractProviderId(user),
      emailVerified: user.emailConfirmedAt != null,
      createdAt: DateTime.parse(user.createdAt),
      updatedAt: user.updatedAt != null ? DateTime.parse(user.updatedAt!) : null,
      lastSignInAt: user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt!) : null,
      metadata: <String, dynamic>{...appMetadata, ...userMetadata},
    );
  }

  /// メールアドレス
  final String email;

  /// 表示名
  final String? displayName;

  /// アバターURL
  final String? avatarUrl;

  /// 認証プロバイダー（google, email など）
  final String? provider;

  /// プロバイダー固有のID
  final String? providerId;

  /// メール認証済みフラグ
  final bool emailVerified;

  /// アカウント作成日時
  final DateTime? createdAt;

  /// 最終更新日時
  final DateTime? updatedAt;

  /// 最終サインイン日時
  final DateTime? lastSignInAt;

  /// 追加のメタデータ
  final Map<String, dynamic>? metadata;

  @override
  String get tableName => "user_profiles";

  /// JSONに変換
  @override
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  /// 有効な表示名を取得
  String get effectiveDisplayName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    return email.split("@").first; // メールアドレスの@より前を使用
  }

  /// 初期化文字（アバター用）
  String get initials {
    final String name = effectiveDisplayName;
    final List<String> words = name.trim().split(" ");
    if (words.length >= 2) {
      return "${words[0][0]}${words[1][0]}".toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return "U"; // Unknown
  }

  /// Google OAuth認証かどうか
  bool get isGoogleAuth => provider?.toLowerCase() == "google";

  /// メール認証かどうか
  bool get isEmailAuth => provider?.toLowerCase() == "email";

  /// アクティブなユーザーかどうか
  bool get isActive => emailVerified && createdAt != null;

  /// プロフィール情報をコピーして新しいインスタンスを作成
  UserProfile copyWith({
    String? email,
    String? displayName,
    String? avatarUrl,
    String? provider,
    String? providerId,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSignInAt,
    Map<String, dynamic>? metadata,
    String? id,
    String? userId,
    bool clearDisplayName = false,
    bool clearAvatarUrl = false,
    bool clearMetadata = false,
  }) => UserProfile(
    email: email ?? this.email,
    displayName: clearDisplayName ? null : (displayName ?? this.displayName),
    avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
    provider: provider ?? this.provider,
    providerId: providerId ?? this.providerId,
    emailVerified: emailVerified ?? this.emailVerified,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    metadata: clearMetadata ? null : (metadata ?? this.metadata),
    id: id ?? this.id,
    userId: userId ?? this.userId,
  );

  /// デバッグ用文字列表現
  @override
  String toString() =>
      "UserProfile("
      "id: $id, "
      "email: $email, "
      "displayName: $displayName, "
      "provider: $provider, "
      "emailVerified: $emailVerified"
      ")";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.avatarUrl == avatarUrl &&
        other.provider == provider &&
        other.emailVerified == emailVerified;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[id, email, displayName, avatarUrl, provider, emailVerified]);

  // =====================================
  // プライベートヘルパーメソッド
  // =====================================

  /// 表示名を抽出
  static String? _extractDisplayName(
    Map<String, dynamic> appMetadata,
    Map<String, dynamic> userMetadata,
  ) =>
      appMetadata["full_name"] as String? ??
      appMetadata["name"] as String? ??
      userMetadata["full_name"] as String? ??
      userMetadata["name"] as String?;

  /// アバターURLを抽出
  static String? _extractAvatarUrl(
    Map<String, dynamic> appMetadata,
    Map<String, dynamic> userMetadata,
  ) =>
      appMetadata["avatar_url"] as String? ??
      appMetadata["picture"] as String? ??
      userMetadata["avatar_url"] as String? ??
      userMetadata["picture"] as String?;

  /// 認証プロバイダーを抽出
  static String? _extractProvider(User user) {
    // user.appMetadata.provider または identities から抽出
    final Map<String, dynamic> appMetadata = user.appMetadata;
    if (appMetadata["provider"] != null) {
      return appMetadata["provider"] as String;
    }

    // identitiesから最初のプロバイダーを取得
    final List<UserIdentity>? identities = user.identities;
    if (identities != null && identities.isNotEmpty) {
      return identities.first.provider;
    }

    return null;
  }

  /// プロバイダー固有IDを抽出
  static String? _extractProviderId(User user) {
    final List<UserIdentity>? identities = user.identities;
    if (identities != null && identities.isNotEmpty) {
      return identities.first.id;
    }
    return null;
  }
}
