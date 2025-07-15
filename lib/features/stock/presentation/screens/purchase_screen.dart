import "package:flutter/material.dart";

/// 仕入れ画面
///
/// 材料の仕入れ処理を行います。
class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("仕入れ")),
    body: const Center(child: Text("仕入れ画面")),
  );
}
