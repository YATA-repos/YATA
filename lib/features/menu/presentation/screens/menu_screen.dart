import "package:flutter/material.dart";

/// メニュー画面
///
/// メニューの一覧表示と管理機能を提供します。
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("メニュー")),
    body: const Center(child: Text("メニュー画面")),
  );
}
