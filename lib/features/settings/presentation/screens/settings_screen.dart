import "package:flutter/material.dart";

/// 設定画面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("設定")),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.settings, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("設定画面", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("実装予定", style: TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}
