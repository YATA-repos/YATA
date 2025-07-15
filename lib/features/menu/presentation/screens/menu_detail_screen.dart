import "package:flutter/material.dart";

/// メニュー詳細画面
///
/// 特定のメニューアイテムの詳細情報を表示します。
class MenuDetailScreen extends StatelessWidget {
  const MenuDetailScreen({required this.menuId, super.key});

  final String menuId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("メニュー詳細: $menuId")),
    body: const Center(child: Text("メニュー詳細画面")),
  );
}
