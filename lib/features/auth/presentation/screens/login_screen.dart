import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/layouts/responsive_padding.dart";
import "../../../../shared/widgets/error_view.dart";
import "../../../../shared/widgets/loading_overlay.dart";
import "../providers/auth_provider.dart";

/// ログイン画面
///
/// Google OAuth認証を使用してユーザーをサインインさせます。
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<bool> authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // 背景グラデーション
          _buildBackground(),

          // メインコンテンツ
          SafeArea(child: ResponsivePadding(child: _buildContent(context, authState))),

          // ローディングオーバーレイ
          if (authState.isLoading) const LoadingOverlay(message: "ログイン中..."),
        ],
      ),
    );
  }

  /// 背景グラデーションを構築
  Widget _buildBackground() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          Theme.of(context).colorScheme.secondary,
        ],
      ),
    ),
  );

  /// メインコンテンツを構築
  Widget _buildContent(BuildContext context, AsyncValue<bool> authState) => AnimatedBuilder(
    animation: _animationController,
    builder: (BuildContext context, Widget? child) => FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: child),
    ),
    child: Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // ヘッダーセクション
                  _buildHeader(),

                  const SizedBox(height: 48),

                  // ログインセクション
                  if (authState.hasError)
                    _buildErrorSection(authState.error!)
                  else
                    _buildLoginSection(),
                ],
              ),
            ),
          ),
        ),

        // フッター
        _buildFooter(),
      ],
    ),
  );

  /// ヘッダーセクションを構築
  Widget _buildHeader() => Column(
    children: <Widget>[
      // アプリアイコン
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(LucideIcons.store, size: 50, color: Theme.of(context).colorScheme.primary),
      ),

      const SizedBox(height: 24),

      // アプリ名
      Text(
        "YATA",
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),

      const SizedBox(height: 8),

      // サブタイトル
      Text(
        "小規模レストラン向け管理システム",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );

  /// ログインセクションを構築
  Widget _buildLoginSection() => Container(
    constraints: const BoxConstraints(maxWidth: 400),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // タイトル
        Text(
          "ログイン",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // 説明文
        Text(
          "Googleアカウントでログインしてください",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Googleログインボタン
        _buildGoogleLoginButton(),

        const SizedBox(height: 16),

        // 利用規約リンク
        _buildTermsAndPrivacy(),
      ],
    ),
  );

  /// Googleログインボタンを構築
  Widget _buildGoogleLoginButton() => ElevatedButton.icon(
    onPressed: _handleGoogleLogin,
    icon: const Icon(LucideIcons.chrome), // Google用アイコンの代替
    label: const Text("Googleでログイン"),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  /// 利用規約とプライバシーポリシーリンクを構築
  Widget _buildTermsAndPrivacy() => Wrap(
    alignment: WrapAlignment.center,
    children: <Widget>[
      Text(
        "ログインすることで、",
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      GestureDetector(
        onTap: _showTermsDialog,
        child: Text(
          "利用規約",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      Text(
        " と ",
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      GestureDetector(
        onTap: _showPrivacyDialog,
        child: Text(
          "プライバシーポリシー",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      Text(
        " に同意したものとみなされます。",
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );

  /// エラーセクションを構築
  Widget _buildErrorSection(Object error) => Container(
    constraints: const BoxConstraints(maxWidth: 400),
    child: ErrorView(
      title: "ログインエラー",
      message: "ログインに失敗しました。もう一度お試しください。",
      onRetry: _handleGoogleLogin,
      compact: true,
    ),
  );

  /// フッターを構築
  Widget _buildFooter() => Column(
    children: <Widget>[
      Text(
        "YATA v1.0.0",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "© 2024 YATA Team",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      ),
    ],
  );

  /// Googleログイン処理
  Future<void> _handleGoogleLogin() async {
    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle();
    } catch (e) {
      // エラーは AuthStateProvider で処理される
    }
  }

  /// 利用規約ダイアログを表示
  void _showTermsDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("利用規約"),
        content: const SingleChildScrollView(
          child: Text(
            "YATAの利用規約\n\n"
            "1. 本アプリケーションは小規模レストラン向けの管理システムです。\n\n"
            "2. ユーザーは本アプリケーションを適切に使用する責任があります。\n\n"
            "3. データの損失や不具合に対して、開発者は責任を負いません。\n\n"
            "4. 本規約は予告なく変更される場合があります。",
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("閉じる")),
        ],
      ),
    );
  }

  /// プライバシーポリシーダイアログを表示
  void _showPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("プライバシーポリシー"),
        content: const SingleChildScrollView(
          child: Text(
            "YATAのプライバシーポリシー\n\n"
            "1. 収集する情報\n"
            "- Googleアカウント情報（メールアドレス、名前）\n"
            "- アプリケーション使用データ\n\n"
            "2. 情報の使用目的\n"
            "- サービス提供のため\n"
            "- サポート対応のため\n\n"
            "3. 情報の保護\n"
            "- 適切なセキュリティ対策を実施\n"
            "- 第三者への不正な提供は行いません",
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("閉じる")),
        ],
      ),
    );
  }
}
