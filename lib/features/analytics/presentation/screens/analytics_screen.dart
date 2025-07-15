import "package:flutter/material.dart";

/// 分析画面
///
/// 各種分析機能のメイン画面です。
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("分析")),
    body: const Center(child: Text("分析画面")),
  );
}
