import "package:flutter/material.dart";
import "shared/themes/themes.dart";

void main() {
  runApp(const YATAApp());
}

/// YATAアプリケーションのメインアプリケーションクラス
class YATAApp extends StatelessWidget {
  const YATAApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "YATA - 屋台管理システム",
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    home: Scaffold(
      body: Center(
        child: Container(
          padding: AppLayout.padding8,
          decoration: BoxDecoration(
            backgroundBlendMode: BlendMode.srcOver,
            color: AppColors.darkCard,
            border: Border.all(color: AppColors.secondary, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Hello YATA!",
            textScaler: TextScaler.linear(3.0),
            style: TextStyle(color: AppColors.background),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    debugShowCheckedModeBanner: false,
  );
}
