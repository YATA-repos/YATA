# データエクスポート画面のスクロールビュー修正計画

**作成日**: 2025-10-15  
**ステータス**: 実装可能  
**優先度**: 高（アプリクラッシュ）

## 問題の概要

設定画面のCSVエクスポート機能ボタンを押すと、以下のエラーが発生しアプリがクラッシュする:

```
Vertical viewport was given unbounded height.
```

エラー発生箇所: `lib/features/export/presentation/pages/data_export_page.dart:98`

## 原因分析

### 根本原因

`YataPageContainer`と`CustomScrollView`のネスト問題:

1. **`YataPageContainer`のデフォルト動作**
   - `scrollable: true`（デフォルト）の場合、内部で`SingleChildScrollView`を生成
   - これにより、子ウィジェットにスクロール可能なコンテナを提供

2. **`data_export_page.dart`の実装**
   ```dart
   body: YataPageContainer(
     child: CustomScrollView(  // ← ネストされたスクロールビュー
       slivers: <Widget>[
         SliverToBoxAdapter(
           child: Padding(
             // ...
           ),
         ),
       ],
     ),
   ),
   ```

3. **問題の発生メカニズム**
   - 外側の`SingleChildScrollView`が内側の`CustomScrollView`に無制限の高さを提供
   - `CustomScrollView`（Viewport）は無制限の高さを処理できず、アサーションエラーを発生
   - Flutterのレンダリングパイプラインが失敗し、アプリがクラッシュ

### 技術的詳細

エラーメッセージより:
```
Viewports expand in the scrolling direction to fill their container. In this case, a vertical
viewport was given an unlimited amount of vertical space in which to expand. This situation
typically happens when a scrollable widget is nested inside another scrollable widget.
```

スタックトレース分析:
- `RenderViewport.computeDryLayout` → `RenderBox.performResize` でアサーション失敗
- `_RenderSingleChildViewport`（外側）と`RenderViewport`（内側）のネスト構造が確認される

## 他の画面での実装パターン

プロジェクト内の他の画面では、この問題を回避するために以下のパターンを採用:

### パターン1: `scrollable: false`の使用

```dart
// order_management_page.dart, order_history_page.dart, order_status_page.dart
body: YataPageContainer(
  scrollable: false,  // ← スクロールを無効化
  child: Column(
    // 内部のウィジェット（テーブルなど）が個別にスクロール制御
  ),
),
```

### パターン2: スクロールビューの重複（問題あり）

```dart
// settings_page.dart（修正が必要な可能性あり）
body: YataPageContainer(
  child: SingleChildScrollView(  // ← YataPageContainer内で既にSingleChildScrollView
    child: Column(
      // ...
    ),
  ),
),
```

**注意**: `settings_page.dart`も同様のネスト問題を抱えている可能性があるが、`SingleChildScrollView`同士のネストは`CustomScrollView`ほど厳密ではないため、現状エラーが発生していない。

## 修正方針

### 推奨アプローチ: オプション1

`YataPageContainer`に`scrollable: false`を指定し、`CustomScrollView`を`Column`に変更:

**理由**:
1. 現在の`CustomScrollView`は単一の`SliverToBoxAdapter`のみを含み、高度なスライバー機能を使用していない
2. `Column`の方がシンプルで、パフォーマンスも良好
3. 他の画面のパターンと一貫性が保たれる
4. 将来的に動的なコンテンツが増えても、`Column`内の`Expanded`や`ListView`で対応可能

### 代替アプローチ: オプション2

`scrollable: false`のみを指定し、`CustomScrollView`を維持:

**理由**:
- 将来的に複雑なスライバーレイアウトが必要になる場合に備える
- 変更範囲が最小限

**デメリット**:
- 現状では`CustomScrollView`の利点がない
- コードの複雑性が増す

## 実装計画

### ステップ1: `data_export_page.dart`の修正

#### 修正前（98行目付近）

```dart
body: YataPageContainer(
  child: CustomScrollView(
    slivers: <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: YataSpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ...
            ],
          ),
        ),
      ),
    ],
  ),
),
```

#### 修正後（オプション1: 推奨）

```dart
body: YataPageContainer(
  scrollable: false,  // スクロールを無効化
  child: SingleChildScrollView(  // 明示的にスクロール制御
    padding: const EdgeInsets.only(
      top: YataSpacingTokens.lg,
      bottom: YataSpacingTokens.xl,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ... 既存のコンテンツ
      ],
    ),
  ),
),
```

**変更点**:
1. `YataPageContainer`に`scrollable: false`を追加
2. `CustomScrollView`と`SliverToBoxAdapter`を削除
3. `SingleChildScrollView`を直接配置
4. `Padding`を`SingleChildScrollView`の`padding`パラメータに移動（オプション）
5. `Column`を直接配置

#### 修正後（オプション2: 代替）

```dart
body: YataPageContainer(
  scrollable: false,  // スクロールを無効化
  child: CustomScrollView(
    slivers: <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: YataSpacingTokens.lg),
          child: Column(
            // ... 既存のコンテンツ
          ),
        ),
      ),
    ],
  ),
),
```

**変更点**:
1. `YataPageContainer`に`scrollable: false`を追加のみ

### ステップ2: テスト

1. **動作確認**
   - データエクスポート画面に遷移
   - 画面がクラッシュせずに表示されることを確認
   - スクロールが正常に機能することを確認

2. **レイアウト確認**
   - 各セクションが正しく表示されることを確認
   - 画面サイズを変更しても正常に動作することを確認（ウィンドウサイズ変更）

3. **機能確認**
   - CSVエクスポートボタンを押下
   - エクスポート処理が正常に完了することを確認

### ステップ3: 他の画面の監査（オプション）

`settings_page.dart`の同様の問題を確認し、必要に応じて修正:

```dart
// settings_page.dart:120-121
body: YataPageContainer(
  child: SingleChildScrollView(  // ← 潜在的なネスト問題
    // ...
  ),
),
```

**推奨修正**:
```dart
body: YataPageContainer(
  scrollable: false,
  child: SingleChildScrollView(
    // ...
  ),
),
```

## 影響範囲

### 変更ファイル

1. `lib/features/export/presentation/pages/data_export_page.dart` - 必須
2. `lib/features/settings/presentation/pages/settings_page.dart` - オプション（監査結果により）

### 影響する機能

- データエクスポート画面のUI表示
- データエクスポート画面のスクロール動作

### リスク評価

- **リスクレベル**: 低
- **理由**: レイアウトの変更のみで、ロジックには影響しない
- **軽減策**: 手動テストによる動作確認

## 実装スケジュール

1. **即時対応** (1時間)
   - `data_export_page.dart`の修正
   - 動作確認テスト

2. **フォローアップ** (30分、オプション)
   - `settings_page.dart`の監査と修正
   - 全画面でのスクロール動作確認

## 学習ポイント

### 今後の開発で注意すべき点

1. **`YataPageContainer`の使用方法**
   - 内部でスクロール可能ウィジェット（`CustomScrollView`, `SingleChildScrollView`, `ListView`など）を使う場合は、必ず`scrollable: false`を指定
   - デフォルトの`scrollable: true`は、内部が静的な`Column`のみの場合に使用

2. **スクロールビューのネスト**
   - Flutterでは、スクロール可能ウィジェットのネストは避ける
   - やむを得ずネストする場合は、内側のスクロールビューに`shrinkWrap: true`と`physics: NeverScrollableScrollPhysics()`を指定

3. **`CustomScrollView`の適切な使用**
   - 複数の異なるタイプのスクロール可能コンテンツ（リスト、グリッドなど）を組み合わせる場合にのみ使用
   - 単純な縦方向スクロールには`SingleChildScrollView` + `Column`で十分

## 参考資料

- [Flutter公式ドキュメント: Slivers](https://docs.flutter.dev/ui/layout/scrolling/slivers)
- [Flutter公式ドキュメント: SingleChildScrollView](https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html)
- プロジェクト内の既存実装:
  - `lib/features/order/presentation/pages/order_management_page.dart`
  - `lib/features/order/presentation/pages/order_history_page.dart`
  - `lib/features/order/presentation/pages/order_status_page.dart`

## チェックリスト

実装時に確認すべき項目:

- [ ] `data_export_page.dart`に`scrollable: false`を追加
- [ ] `CustomScrollView`を`SingleChildScrollView`に変更（オプション1の場合）
- [ ] `SliverToBoxAdapter`を削除（オプション1の場合）
- [ ] エラーが発生しないことを確認
- [ ] スクロールが正常に機能することを確認
- [ ] 各セクションが正しく表示されることを確認
- [ ] CSVエクスポート機能が正常に動作することを確認
- [ ] `settings_page.dart`の監査（オプション）
- [ ] コードレビュー実施
- [ ] ドキュメント更新（必要に応じて）

## 承認

このプランを承認し、実装を進めてよろしいでしょうか？
