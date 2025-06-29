import "package:flutter/material.dart";

// temporary skelton app

/// アプリケーションのエントリーポイント
void main() {
  runApp(const MyApp());
}

/// メインアプリケーションウィジェット
class MyApp extends StatelessWidget {
  /// コンストラクタ
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Flutter Demo",
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const MyHomePage(title: "Flutter Demo Home Page"),
  );
}

/// ホームページウィジェット
class MyHomePage extends StatefulWidget {
  /// コンストラクタ
  const MyHomePage({required this.title, super.key});

  /// ページタイトル
  final String title;

  @override
  /// ステートを作成
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(widget.title),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text("You have pushed the button this many times:"),
          Text("$_counter", style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _incrementCounter,
      tooltip: "Increment",
      child: const Icon(Icons.add),
    ),
  );
}
