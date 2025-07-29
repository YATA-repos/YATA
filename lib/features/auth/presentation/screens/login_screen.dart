import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/auth/auth_service.dart";
import "../../../../core/constants/app_strings/app_strings.dart";
import "../../../../core/providers/auth_providers.dart";
import "../../../../core/utils/log_service.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/cards/app_card.dart";
import "../../../../shared/widgets/common/loading_indicator.dart";

/// ログイン画面
/// 
/// Google OAuth認証を提供
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    LogService.info("LoginScreen", "DEBUG: === Login Screen Build Started ===");
    LogService.info("LoginScreen", "DEBUG: Building login screen UI");
    
    final bool isLoading = ref.watch(authLoadingProvider);
    final String? error = ref.watch(authErrorProvider);
    
    LogService.info("LoginScreen", "DEBUG: Current state - isLoading: $isLoading, hasError: ${error != null}");
    if (error != null) {
      LogService.info("LoginScreen", "DEBUG: Current error: $error");
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: AppLayout.paddingLarge,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // アプリロゴ・タイトル
                Icon(
                  LucideIcons.store,
                  size: 80,
                  color: AppColors.primary,
                ),
                AppLayout.vSpacerMedium,
                Text(
                  AppStrings.titleApp,
                  style: AppTextTheme.cardTitle.copyWith(fontSize: 32),
                ),
                AppLayout.vSpacerSmall,
                Text(
                  AppStrings.descriptionApp,
                  style: AppTextTheme.cardDescription,
                  textAlign: TextAlign.center,
                ),
                AppLayout.vSpacerLarge,

                // ログインカード
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        AppStrings.textLogin,
                        style: AppTextTheme.cardTitle,
                        textAlign: TextAlign.center,
                      ),
                      AppLayout.vSpacerMedium,

                      // エラー表示
                      if (error != null) ...<Widget>[
                        Container(
                          padding: AppLayout.paddingDefault,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: AppLayout.borderRadiusSmall,
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                LucideIcons.alertCircle,
                                color: AppColors.danger,
                                size: 20,
                              ),
                              AppLayout.hSpacerSmall,
                              Expanded(
                                child: Text(
                                  error,
                                  style: AppTextTheme.cardDescription.copyWith(color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppLayout.vSpacerMedium,
                      ],

                      // ローディング表示
                      if (isLoading) ...<Widget>[
                        const LoadingIndicator(),
                        AppLayout.vSpacerMedium,
                        Text(
                          AppStrings.textAuthenticating,
                          style: AppTextTheme.cardDescription,
                          textAlign: TextAlign.center,
                        ),
                      ] else ...<Widget>[
                        // Googleログインボタン
                        AppButton(
                          onPressed: () => _signInWithGoogle(ref, context),
                          variant: ButtonVariant.outline,
                          size: ButtonSize.large,
                          isFullWidth: true,
                          text: AppStrings.buttonGoogleLogin,
                          icon: const Icon(LucideIcons.chrome),
                        ),
                        AppLayout.vSpacerMedium,

                        // 説明テキスト
                        Text(
                          AppStrings.descriptionGoogleAuth,
                          style: AppTextTheme.cardDescription,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                AppLayout.vSpacerLarge,

                // 開発者向け情報
                Container(
                  padding: AppLayout.paddingDefault,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: AppLayout.borderRadiusSmall,
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            LucideIcons.info,
                            size: 16,
                            color: AppColors.mutedForeground,
                          ),
                          AppLayout.hSpacerSmall,
                          Text(
                            AppStrings.textDeveloperInfo,
                            style: AppTextTheme.cardDescription.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      AppLayout.vSpacerSmall,
                      Text(
                        AppStrings.textSupabaseEnvInfo,
                        style: AppTextTheme.cardDescription.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Googleログイン処理
  Future<void> _signInWithGoogle(WidgetRef ref, BuildContext context) async {
    LogService.info("LoginScreen", "DEBUG: ========================================");
    LogService.info("LoginScreen", "DEBUG: === Google Sign-In Button Pressed ===");
    LogService.info("LoginScreen", "DEBUG: Time: ${DateTime.now().toIso8601String()}");
    LogService.info("LoginScreen", "DEBUG: Context mounted: ${context.mounted}");
    LogService.info("LoginScreen", "DEBUG: ========================================");
    
    final AuthError authErrorNotifier = ref.read(authErrorProvider.notifier);
    final AuthLoading authLoadingNotifier = ref.read(authLoadingProvider.notifier);

    try {
      LogService.info("LoginScreen", "DEBUG: [1/4] Clearing previous errors...");
      // エラーをクリア
      authErrorNotifier.clearError();
      LogService.info("LoginScreen", "DEBUG: [1/4] ✅ Previous errors cleared");
      
      LogService.info("LoginScreen", "DEBUG: [2/4] Setting loading state to true...");
      // ローディング開始
      authLoadingNotifier.setLoading(true);
      LogService.info("LoginScreen", "DEBUG: [2/4] ✅ Loading state set to true");

      LogService.info("LoginScreen", "DEBUG: [3/4] Getting auth service instance...");
      // 認証実行
      final SupabaseClientService authService = ref.read(supabaseClientServiceProvider);
      LogService.info("LoginScreen", "DEBUG: [3/4] ✅ Auth service instance obtained");
      LogService.info("LoginScreen", "DEBUG: [3/4] Starting Google sign-in process...");
      
      final bool success = await authService.signInWithGoogle();
      
      LogService.info("LoginScreen", "DEBUG: [3/4] ✅ Google sign-in process completed");
      LogService.info("LoginScreen", "DEBUG: [3/4] Authentication result: $success");

      LogService.info("LoginScreen", "DEBUG: [4/4] Processing authentication result...");
      if (success && context.mounted) {
        LogService.info("LoginScreen", "DEBUG: [4/4] ✅ Authentication successful, redirecting to home");
        LogService.info("LoginScreen", "DEBUG: [4/4] Context still mounted: ${context.mounted}");
        // 認証成功時はホームへリダイレクト
        context.go("/");
        LogService.info("LoginScreen", "DEBUG: [4/4] ✅ Redirect to home completed");
      } else {
        LogService.warning("LoginScreen", "DEBUG: [4/4] ❌ Authentication failed or context unmounted");
        LogService.warning("LoginScreen", "DEBUG: [4/4] - Success: $success, Context mounted: ${context.mounted}");
        // 認証が失敗した場合（falseが返された）
        authErrorNotifier.setError("認証プロセスが完了しませんでした。再度お試しください。");
      }
    } on TimeoutException catch (e) {
      LogService.error("LoginScreen", "DEBUG: ❌ TimeoutException caught in login");
      LogService.error("LoginScreen", "DEBUG: - Message: ${e.message}");
      LogService.error("LoginScreen", "DEBUG: - Duration: ${e.duration}");
      // タイムアウト例外
      authErrorNotifier.setError(e.message ?? "認証処理がタイムアウトしました。再度お試しください。");
    } on SupabaseAuthException catch (e) {
      LogService.error("LoginScreen", "DEBUG: ❌ SupabaseAuthException caught in login");
      LogService.error("LoginScreen", "DEBUG: - Message: ${e.message}");
      // Supabase認証関連の例外（ユーザー向けメッセージが設定済み）
      authErrorNotifier.setError(e.message);
    } on SupabaseClientException catch (e) {
      LogService.error("LoginScreen", "DEBUG: ❌ SupabaseClientException caught in login");
      LogService.error("LoginScreen", "DEBUG: - Message: ${e.message}");
      // Supabaseクライアント関連の例外（ユーザー向けメッセージが設定済み）
      authErrorNotifier.setError(e.message);
    } catch (e, stackTrace) {
      LogService.error("LoginScreen", "DEBUG: ❌ Unexpected exception caught in login");
      LogService.error("LoginScreen", "DEBUG: - Type: ${e.runtimeType}");
      LogService.error("LoginScreen", "DEBUG: - Message: $e");
      LogService.error("LoginScreen", "DEBUG: - Stack trace: $stackTrace");
      // その他の予期しない例外
      authErrorNotifier.setError("予期しないエラーが発生しました。しばらく待ってから再度お試しください。");
      // デバッグ用にログ出力
      LogService.error("LoginScreen", "Unexpected error in login: ${e.runtimeType} - $e", e);
    } finally {
      LogService.info("LoginScreen", "DEBUG: === Login process completed, setting loading to false ===");
      authLoadingNotifier.setLoading(false);
      LogService.info("LoginScreen", "DEBUG: ✅ Loading state set to false");
      LogService.info("LoginScreen", "DEBUG: ========================================");
    }
  }
}