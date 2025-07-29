import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../core/auth/auth_service.dart";

/// 認証ガード
/// 
/// ルーティング時に認証状態をチェックし、未認証の場合はログイン画面へリダイレクト
class AuthGuard {
  AuthGuard._();

  /// 認証チェック
  /// 
  /// [context] ビルドコンテキスト
  /// [state] ルーター状態
  /// Returns: 認証済みの場合はnull、未認証の場合はリダイレクト先
  static String? checkAuth(BuildContext context, GoRouterState state) {
    final SupabaseClientService authService = SupabaseClientService.instance;
    
    // 認証が初期化されていない場合は通す（開発時の対応）
    try {
      final bool isSignedIn = authService.isSignedIn;
      
      // 既にログイン画面にいる場合
      if (state.matchedLocation == "/login") {
        // 認証済みならホームにリダイレクト
        return isSignedIn ? "/" : null;
      }
      
      // 未認証の場合はログイン画面にリダイレクト
      if (!isSignedIn) {
        return "/login";
      }
      
      // 認証済みの場合は通す
      return null;
    } catch (e) {
      // Supabaseが初期化されていない場合は通す（開発時の対応）
      return null;
    }
  }
}