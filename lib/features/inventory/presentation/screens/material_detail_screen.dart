import "package:flutter/material.dart";

/// 材料詳細画面
///
/// 特定の材料の詳細情報を表示します。
class MaterialDetailScreen extends StatelessWidget {
  const MaterialDetailScreen({required this.materialId, super.key});

  final String materialId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("材料詳細: $materialId")),
    body: const Center(child: Text("材料詳細画面")),
  );
}
