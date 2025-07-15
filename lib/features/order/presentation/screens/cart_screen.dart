import "package:flutter/material.dart";

/// カート画面
///
/// 現在のカートの内容を表示し、注文の確定を行います。
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("カート")),
    body: const Center(child: Text("カート画面")),
  );
}
