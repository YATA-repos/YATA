import "package:supabase_flutter/supabase_flutter.dart" as supabase;

import "../../../core/auth/auth_service.dart";
import "../../../core/validation/input_validator.dart";
import "../models/user_model.dart";
import "../repositories/user_repository.dart";

/// 認証サービス
///
/// 認証に関するビジネスロジックを提供します。
/// SupabaseClientServiceとUserRepositoryを橋渡しします。
class AuthService {
  AuthService({
    required SupabaseClientService supabaseAuthService,
    required UserRepository userRepository,
  }) : _supabaseAuthService = supabaseAuthService,
       _userRepository = userRepository;

  final SupabaseClientService _supabaseAuthService;
  final UserRepository _userRepository;

  /// 現在ログイン中のユーザーかどうか
  bool get isSignedIn => _supabaseAuthService.isSignedIn;

  /// 現在のSupabaseユーザー
  supabase.User? get currentSupabaseUser => _supabaseAuthService.currentUser;

  /// 現在のセッション
  supabase.Session? get currentSession => _supabaseAuthService.currentSession;

  /// 認証状態の変更を監視するStream
  Stream<supabase.AuthState> get authStateChanges => _supabaseAuthService.authStateChanges;

  /// 現在のユーザー情報を取得（データベースから）
  Future<UserModel?> getCurrentUser() async {
    final supabase.User? currentUser = currentSupabaseUser;
    if (currentUser == null) {
      return null;
    }

    try {
      // データベースからユーザー情報を取得
      final UserModel? user = await _userRepository.getById(currentUser.id);

      // データベースにユーザーが存在しない場合は作成
      return user ?? await _createUserFromSupabaseUser(currentUser);
    } catch (e) {
      // エラーログはリポジトリで出力済み
      return null;
    }
  }

  /// Googleでサインイン
  Future<UserModel?> signInWithGoogle() async {
    try {
      final bool success = await _supabaseAuthService.signInWithGoogle();
      if (!success) {
        return null;
      }

      // サインイン成功後、ユーザー情報を取得/作成
      final UserModel? user = await getCurrentUser();
      if (user != null) {
        // 最終ログイン時刻を更新
        await _userRepository.updateLastSignIn(user.id!);
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      await _supabaseAuthService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// 認証コールバック処理
  Future<UserModel?> handleAuthCallback(String callbackUrl) async {
    try {
      final supabase.User? user = await _supabaseAuthService.handleAuthCallback(callbackUrl);
      if (user == null) {
        return null;
      }

      // ユーザー情報を取得/作成
      final UserModel? userModel = await getCurrentUser();
      if (userModel != null) {
        // 最終ログイン時刻を更新
        await _userRepository.updateLastSignIn(userModel.id!);
      }

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザープロフィールを更新
  Future<UserModel?> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    // 入力検証
    final List<ValidationResult> validationResults = <ValidationResult>[
      if (displayName != null)
        InputValidator.validateString(
          displayName,
          required: true,
          minLength: 1,
          maxLength: 50,
          fieldName: "表示名",
        ),
      if (avatarUrl != null) InputValidator.validateUrl(avatarUrl),
      if (phoneNumber != null)
        InputValidator.validateString(
          phoneNumber,
          pattern: RegExp(r"^[\d\-\+\(\)]{10,15}$"),
          fieldName: "電話番号",
        ),
    ];

    final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
    if (errors.isNotEmpty) {
      final List<String> errorMessages = InputValidator.getErrorMessages(errors);
      throw ArgumentError("プロフィール更新の入力エラー: ${errorMessages.join(', ')}");
    }

    final UserModel? currentUser = await getCurrentUser();
    if (currentUser == null) {
      return null;
    }

    try {
      return await _userRepository.updateProfile(
        currentUser.id!,
        displayName: displayName,
        avatarUrl: avatarUrl,
        phoneNumber: phoneNumber,
        metadata: metadata,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーのロールを取得
  Future<UserRole?> getUserRole() async {
    final UserModel? user = await getCurrentUser();
    return user?.role;
  }

  /// 管理者権限があるかどうか
  Future<bool> isAdmin() async {
    final UserModel? user = await getCurrentUser();
    return user?.role.isAdmin ?? false;
  }

  /// スタッフ権限があるかどうか
  Future<bool> isStaff() async {
    final UserModel? user = await getCurrentUser();
    return user?.role.isStaff ?? false;
  }

  /// メールアドレスでユーザーを検索
  Future<UserModel?> findUserByEmail(String email) async {
    // メールアドレスの検証
    final ValidationResult emailValidation = InputValidator.validateEmail(email, required: true);
    if (!emailValidation.isValid) {
      throw ArgumentError("無効なメールアドレス: ${emailValidation.errorMessage}");
    }

    try {
      return await _userRepository.findByEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーが存在するかどうか確認
  Future<bool> userExists(String userId) async {
    try {
      return await _userRepository.existsById(userId);
    } catch (e) {
      return false;
    }
  }

  /// Supabaseユーザーからユーザーモデルを作成
  Future<UserModel?> _createUserFromSupabaseUser(supabase.User supabaseUser) async {
    final UserModel newUser = UserModel(
      id: supabaseUser.id,
      userId: supabaseUser.id,
      email: supabaseUser.email ?? "",
      displayName:
          supabaseUser.userMetadata?["full_name"] as String? ??
          supabaseUser.userMetadata?["name"] as String?,
      avatarUrl: supabaseUser.userMetadata?["avatar_url"] as String?,
      phoneNumber: supabaseUser.phone,
      emailVerified: supabaseUser.emailConfirmedAt != null,
      lastSignInAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: supabaseUser.userMetadata,
    );

    try {
      return await _userRepository.create(newUser);
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーデータを同期（Supabaseとデータベース間）
  Future<UserModel?> syncUserData() async {
    final supabase.User? currentUser = currentSupabaseUser;
    if (currentUser == null) {
      return null;
    }

    try {
      UserModel? user = await _userRepository.getById(currentUser.id);

      if (user == null) {
        // ユーザーが存在しない場合は作成
        user = await _createUserFromSupabaseUser(currentUser);
      } else {
        // 既存ユーザーの情報を更新（Supabaseの最新情報で）
        final Map<String, dynamic> updates = <String, dynamic>{};
        bool needsUpdate = false;

        if (user.email != currentUser.email && currentUser.email != null) {
          updates["email"] = currentUser.email;
          needsUpdate = true;
        }

        if (user.emailVerified != (currentUser.emailConfirmedAt != null)) {
          updates["email_verified"] = currentUser.emailConfirmedAt != null;
          needsUpdate = true;
        }

        final String? supabaseDisplayName =
            currentUser.userMetadata?["full_name"] as String? ??
            currentUser.userMetadata?["name"] as String?;
        if (user.displayName != supabaseDisplayName && supabaseDisplayName != null) {
          updates["display_name"] = supabaseDisplayName;
          needsUpdate = true;
        }

        final String? supabaseAvatarUrl = currentUser.userMetadata?["avatar_url"] as String?;
        if (user.avatarUrl != supabaseAvatarUrl && supabaseAvatarUrl != null) {
          updates["avatar_url"] = supabaseAvatarUrl;
          needsUpdate = true;
        }

        if (needsUpdate) {
          updates["updated_at"] = DateTime.now().toIso8601String();
          await _userRepository.updateById(user.id!, updates);
          user = await _userRepository.getById(user.id!);
        }
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }
}
