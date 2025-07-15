import "package:flutter/material.dart";

/// 売上分析画面
///
/// 売上に関する分析データを表示します。
class SalesAnalyticsScreen extends StatelessWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("売上分析")),
    body: const Center(child: Text("売上分析画面")),
  );
}
