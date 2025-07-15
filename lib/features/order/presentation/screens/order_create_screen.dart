import "package:flutter/material.dart";

/// 注文作成画面
///
/// 新しい注文を作成するための画面です。
class OrderCreateScreen extends StatelessWidget {
  const OrderCreateScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("注文作成")),
    body: const Center(child: Text("注文作成画面")),
  );
}
