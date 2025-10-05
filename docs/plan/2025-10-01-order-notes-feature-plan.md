# 注文メモ機能 実装計画

## 概要

注文管理画面（Order Management Page）に、注文に対するメモ（備考）を追加する機能を実装する。

## 背景

- `Order`モデルには既に`notes`フィールドが存在している
- `OrderCheckoutRequest`でも`notes`パラメータが定義されている
- しかし、現在の注文管理画面UIには、ユーザーがメモを入力するためのインターフェースが存在しない

## 実装範囲

### 1. UIコンポーネントの追加

#### 1.1 注文メモ入力フィールド

**配置場所**: 「現在の注文」セクション（`_CurrentOrderSection`）内、合計金額表示の上部

**仕様**:
- テキスト入力フィールド（複数行対応）
- プレースホルダー: 「注文メモ（例: アレルギー対応、調理指示など）」
- 最大文字数: 500文字
- オプション入力（空欄可）

#### 1.2 メモ表示の視覚的デザイン

- ボーダー付きのテキストフィールド
- 既存のYATAデザインシステムのトークンを使用
- 適切なスペーシング（`YataSpacingTokens`）

### 2. 状態管理の追加

#### 2.1 `OrderManagementState`の拡張

**追加フィールド**:
```dart
/// 注文メモ
final String orderNotes;
```

**初期値**: 空文字列 `""`

#### 2.2 `OrderManagementController`の拡張

**追加メソッド**:
```dart
/// 注文メモを更新する
void updateOrderNotes(String notes)
```

### 3. データフローの統合

現時点では、チェックアウト機能が完全に実装されていないため、以下の対応を行う:

1. 状態管理層でメモを保持
2. 将来的にチェックアウトダイアログが実装される際、この状態値を`OrderCheckoutRequest.notes`に渡せるように準備

## 実装の詳細

### ファイル変更

1. **`lib/features/order/presentation/controllers/order_management_controller.dart`**
   - `OrderManagementState`に`orderNotes`フィールド追加
   - `copyWith`メソッドに`orderNotes`パラメータ追加
   - `OrderManagementController`に`updateOrderNotes`メソッド追加

2. **`lib/features/order/presentation/pages/order_management_page.dart`**
   - `_CurrentOrderSection`内に`TextField`ウィジェットを追加
   - 適切な位置（合計金額の上、ボタンの下）に配置

### UI配置

```
現在の注文
├── 注文番号バッジ
├── 注文アイテムリスト（スクロール可能）
├── 区切り線
├── 小計
├── 消費税
├── 合計
├── [新規] 注文メモ入力フィールド ← ここに追加
└── ボタン（クリア・会計）
```

## 制約事項

- チェックアウトダイアログは現時点で未実装のため、メモの実際の保存処理は行わない
- 状態管理層でのみデータを保持
- 将来的な実装時に、この状態値を使用できるように準備

## テスト観点

- メモ入力時に状態が正しく更新されるか
- 長いテキストが適切に表示されるか
- カートをクリアした際にメモもクリアされるか

## 参考

- `Order`モデル: `lib/features/order/models/order_model.dart`
- `OrderCheckoutRequest`: `lib/features/order/dto/order_dto.dart`
- 既存の入力コンポーネント: `lib/shared/components/inputs/`
