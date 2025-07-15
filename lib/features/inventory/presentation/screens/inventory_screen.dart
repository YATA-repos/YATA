import "package:flutter/material.dart";

/// 在庫管理画面
///
/// 在庫の一覧表示と管理機能を提供します。
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("在庫管理")),
    body: const Center(child: Text("在庫管理画面")),
  );
}
