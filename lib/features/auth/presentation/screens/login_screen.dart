import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../models/auth_state.dart";
import "../providers/auth_providers.dart";

/// ログイン画面
/// 
/// Google OAuth認証を通じてユーザーログインを提供します。
/// 認証状態に応じて適切なUIを表示し、認証成功時には
/// 適切なページにリダイレクトします。
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authStateNotifierProvider);
    final AuthStateNotifier authNotifier = ref.read(authStateNotifierProvider.notifier);

    // 認証済みの場合は自動的にダッシュボードにリダイレクト
    // これはAuthGuardでも処理されるが、二重の安全策として実装
    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go("/");
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // アプリロゴ・タイトル部分
              Column(
                children: <Widget>[
                  // アプリアイコン
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.storefront,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // アプリタイトル
                  Text(
                    "YATA",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // サブタイトル
                  Text(
                    r"屋台・小規模レストラン向け\n在庫・注文管理システム",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // 認証状態に応じたコンテンツ
              _buildAuthContent(context, authState, authNotifier),
              
              const SizedBox(height: 48),
              
              // フッター情報
              Text(
                "安全なGoogle認証でログインします",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 認証状態に応じたコンテンツを構築
  Widget _buildAuthContent(
    BuildContext context, 
    AuthState authState, 
    AuthStateNotifier authNotifier,
  ) {
    // 認証処理中
    if (authState.isAuthenticating) {
      return Column(
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            "認証処理中...",
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // エラー状態
    if (authState.hasError) {
      return Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  "認証エラー",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getErrorMessage(authState.error),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // リトライボタンとログインボタンを並べて表示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              // リトライボタン（ネットワークエラーなどの場合）
              if (_shouldShowRetryButton(authState.error))
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleRetry(context, authNotifier),
                    icon: const Icon(Icons.refresh),
                    label: const Text("再試行"),
                  ),
                ),
              if (_shouldShowRetryButton(authState.error))
                const SizedBox(width: 12),
              // ログインボタン
              Expanded(
                child: _buildLoginButton(context, authNotifier),
              ),
            ],
          ),
        ],
      );
    }

    // 通常状態（ログインボタン表示）
    return _buildLoginButton(context, authNotifier);
  }

  /// ログインボタンを構築
  Widget _buildLoginButton(BuildContext context, AuthStateNotifier authNotifier) => ElevatedButton.icon(
      onPressed: () => _handleGoogleSignIn(context, authNotifier),
      icon: const Icon(Icons.login),
      label: const Text("Googleでログイン"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

  /// Google認証処理
  Future<void> _handleGoogleSignIn(
    BuildContext context, 
    AuthStateNotifier authNotifier,
  ) async {
    try {
      await authNotifier.signInWithGoogle();
      
      // 認証成功時の追加処理があれば実装
      // 現在はAuthGuardによる自動リダイレクトに任せる
    } catch (e) {
      // エラーは既にAuthStateNotifierで処理されている
      // 必要に応じて追加のエラーハンドリングを実装
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("認証に失敗しました: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// リトライボタンを表示すべきかどうか判定
  bool _shouldShowRetryButton(String? error) {
    if (error == null) {
      return false;
    }
    
    final String lowerError = error.toLowerCase();
    final List<String> retryableErrors = <String>[
      "network_error",
      "timeout", 
      "server_error",
      "connection",
      "failed to fetch",
      "network request failed",
    ];
    
    return retryableErrors.any(lowerError.contains);
  }

  /// リトライ処理
  Future<void> _handleRetry(
    BuildContext context,
    AuthStateNotifier authNotifier,
  ) async {
    // エラー状態をクリア
    authNotifier.clearError();
    
    // 少し待機してからリトライ
    await Future<void>.delayed(const Duration(milliseconds: 500));
    
    // 再度認証を試行
    if (context.mounted) {
      await _handleGoogleSignIn(context, authNotifier);
    }
  }

  /// エラーメッセージを整形
  String _getErrorMessage(String? error) {
    if (error == null || error.isEmpty) {
      return "不明なエラーが発生しました";
    }

    // よくあるエラーメッセージを日本語に変換
    final Map<String, String> errorMessages = <String, String>{
      "popup_closed_by_user": "認証がキャンセルされました",
      "network_error": r"ネットワークエラーが発生しました\n\nインターネット接続を確認してください",
      "invalid_request": r"認証リクエストが無効です\n\n設定を確認してください",
      "access_denied": r"アクセスが拒否されました\n\nGoogleアカウントへのアクセス許可が必要です",
      "session_expired": r"セッションの有効期限が切れました\n\n再度ログインしてください",
      "timeout": r"認証処理がタイムアウトしました\n\n再度お試しください",
      "server_error": r"サーバーエラーが発生しました\n\nしばらく時間をおいて再度お試しください",
      "oauth_error": "OAuth認証でエラーが発生しました",
      "config_error": "認証設定にエラーがあります",
    };

    final String lowerError = error.toLowerCase();
    for (final MapEntry<String, String> entry in errorMessages.entries) {
      if (lowerError.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // その他のエラーメッセージを整形
    if (error.length > 100) {
      return "認証エラーが発生しました\\n\\n詳細: ${error.substring(0, 100)}...";
    }

    return "認証エラー: $error";
  }
}