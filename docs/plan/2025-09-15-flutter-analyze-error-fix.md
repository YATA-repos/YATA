# flutter analyze error修正計画（2025-09-15）

## 背景

- `flutter analyze` 実行時に `lib/app/wiring/provider.dart` で `ref` という未定義の名前付き引数が複数箇所で指定されている。
- 問題の対象は `MaterialManagementService` など、`Ref` を受け取らないサービス群のコンストラクタ呼び出し。

## 対応方針

1. `lib/app/wiring/provider.dart` を確認し、該当サービス生成時に渡している `ref` 引数を除去する。
2. 支障がないことを確認した上で `flutter analyze` を再実行し、errorが解消されたことを確認する。

## 留意点

- `InventoryService` 本体は `Ref` を必要とするため、`InventoryService` 生成時の `ref` 引数は残す。
- 分析結果にwarningやinfoレベルの指摘が複数存在するが、今回の範囲はerror解消に限定する。
