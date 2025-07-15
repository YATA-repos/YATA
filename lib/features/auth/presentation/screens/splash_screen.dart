import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/auth/auth_service.dart";
import "../../../../core/utils/logger_mixin.dart";
import "../../../../routing/route_constants.dart";
import "../providers/auth_provider.dart";

/// スプラッシュ画面
///
/// アプリケーション起動時の初期化処理を行い、
/// 認証状態に応じて適切な画面にリダイレクトします。
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin, LoggerMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // アニメーションコントローラーの初期化
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    // アニメーション開始
    _animationController.forward();

    // 初期化処理を開始
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// アプリケーション初期化処理
  Future<void> _initializeApp() async {
    try {
      // Supabaseクライアントの初期化
      await SupabaseClientService.initialize();

      // 最低表示時間を確保（UX向上のため）
      await Future<void>.delayed(const Duration(milliseconds: 2000));

      if (!mounted) {
        return;
      }

      // 認証状態をチェックしてリダイレクト
      await _checkAuthAndRedirect();
    } catch (e) {
      if (!mounted) {
        return;
      }

      // 初期化エラー時はエラーダイアログを表示
      logError("Application initialization failed", e);
      _showInitializationError(e);
    }
  }

  /// 認証状態をチェックしてリダイレクト
  Future<void> _checkAuthAndRedirect() async {
    try {
      final SupabaseClientService authService = ref.read(authServiceProvider);
      final bool isAuthenticated = authService.isSignedIn;

      if (!mounted) {
        return;
      }

      if (isAuthenticated) {
        // 認証済みの場合はホーム画面へ
        context.go(AppRoutes.home);
      } else {
        // 未認証の場合はログイン画面へ
        context.go(AppRoutes.login);
      }
    } catch (e) {
      // 認証チェックエラー時はログイン画面へ
      logWarning("Authentication check failed, redirecting to login");
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  /// 初期化エラーダイアログを表示
  void _showInitializationError(dynamic error) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("初期化エラー"),
        content: Text(
          "アプリケーションの初期化に失敗しました。\n\n"
          "エラー詳細: ${error.toString()}",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // 再試行
            },
            child: const Text("再試行"),
          ),
          TextButton(onPressed: () => context.go(AppRoutes.login), child: const Text("ログイン画面へ")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.primary,
    body: Center(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (BuildContext context, Widget? child) => FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(scale: _scaleAnimation, child: child),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // アプリアイコン
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.store,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 32),

            // アプリ名
            Text(
              "YATA",
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
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
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // ローディングインジケーター
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
              ),
            ),

            const SizedBox(height: 16),

            // ローディングテキスト
            Text(
              "初期化中...",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// スプラッシュ画面のアニメーション付きロゴ
class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(duration: const Duration(seconds: 3), vsync: this);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // アニメーション開始
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(<Listenable?>[_rotationController, _pulseController]),
    builder: (BuildContext context, Widget? child) => Transform.scale(
      scale: _pulseAnimation.value,
      child: Transform.rotate(angle: _rotationAnimation.value * 2 * 3.14159, child: child),
    ),
    child: Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(LucideIcons.store, size: 40, color: Theme.of(context).colorScheme.onPrimary),
    ),
  );
}
