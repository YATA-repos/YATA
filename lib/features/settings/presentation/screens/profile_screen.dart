import "package:flutter/material.dart";

/// プロフィール画面
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("プロフィール")),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.person, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("プロフィール画面", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("実装予定", style: TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}
