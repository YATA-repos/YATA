import "package:flutter/material.dart";

/// UI関連定数
///
/// FlutterのUI層で使用される定数を管理します。
class AppConstants {
  AppConstants._();

  // アニメーション時間
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationSplash = Duration(milliseconds: 1000);

  // カーブ
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve bounceInOut = Curves.bounceInOut;

  // UI操作タイムアウト
  static const Duration tapTimeout = Duration(milliseconds: 300);
  static const Duration longPressTimeout = Duration(milliseconds: 500);

  // UI状態関連
  static const Duration loadingMinDisplay = Duration(milliseconds: 500);
  static const Duration debounceSearch = Duration(milliseconds: 300);
  static const Duration tooltipDelay = Duration(milliseconds: 500);

  // UI制限（入力フィールド用）
  static const int maxCommentLength = 500;
}
