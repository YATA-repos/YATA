import "package:flutter/material.dart";

/// 在庫分析画面
///
/// 在庫に関する分析データを表示します。
class InventoryAnalyticsScreen extends StatelessWidget {
  const InventoryAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("在庫分析")),
    body: const Center(child: Text("在庫分析画面")),
  );
}
