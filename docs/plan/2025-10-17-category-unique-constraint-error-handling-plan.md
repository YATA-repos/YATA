# カテゴリ UNIQUE制約違反エラーハンドリング実装計画（2025-10-17）

## 背景

メニュー・在庫カテゴリのデータベーステーブル設計において、カテゴリ名に UNIQUE制約が設定されている。

重複するカテゴリ名でカテゴリを作成・更新しようとした際、バックエンドから UNIQUE制約違反エラーが返ってくるが、現在のクライアント側の実装では汎用的なエラーメッセージのみが表示され、ユーザーが重複が原因であることを認識しづらい。

ユーザーに対して「このカテゴリ名は既に使用されています」といった具体的で分かりやすいエラーメッセージを表示し、再命名を促すようにすることで、利用体験を向上させる。

## 課題分析

### 現状

1. **エラーハンドリングの流れ**
   - `lib/features/inventory/presentation/controllers/inventory_management_controller.dart` の `createCategory()` / `renameCategory()` メソッド
   - サービス層呼び出し時に例外が発生 → `ErrorHandler.instance.handleError(error)` で汎用メッセージに変換
   - UI（ダイアログ）に "予期しないエラーが発生しました。もう一度お試しください。" のようなメッセージが表示される

2. **バックエンドからのエラー形式**
   - Supabase PostgreSQL の UNIQUE制約違反時、特定のエラーコードが返される
   - エラーコード例: `23505` (PostgreSQL)、`duplicate_key_value_violates_unique_constraint`
   - 現在は `RepositoryException` などのラッパー例外で捕捉されている

3. **現在の実装上の課題**
   - `ErrorHandler.handleError()` が例外の詳細情報を解析していない
   - UNIQUE制約違反を特別に識別するロジックがない
   - コントローラー側でもクライアント側での重複チェック（`state.categoryEntities` の参照）は実装済みだが、サーバー側でのチェック後のエラーハンドリングが不足している

### 関連ファイル

1. **コントローラー**:
   - `lib/features/inventory/presentation/controllers/inventory_management_controller.dart`
     - `createCategory()` (539～567行目)
     - `renameCategory()` (568～620行目)
   - `lib/features/menu/presentation/controllers/menu_management_controller.dart`
     - `createCategory()` (323～343行目)
     - `renameCategory()` (350～366行目)

2. **エラーハンドリング**:
   - `lib/core/utils/error_handler.dart`
   - `lib/core/constants/exceptions/exceptions.dart`

3. **サービス層**:
   - `lib/features/inventory/services/material_management_service.dart`
   - `lib/features/menu/services/menu_service.dart`

4. **UI**:
   - `lib/features/inventory/presentation/pages/inventory_management_page.dart` (カテゴリ追加ダイアログ)
   - `lib/features/menu/presentation/pages/menu_management_page.dart` (同様のダイアログ)

## 解決方針

### レベル 1: エラーメッセージの改善（短期）

例外オブジェクトから UNIQUE制約違反を検出し、具体的なメッセージを返すよう改善。

1. **`ErrorHandler` の拡張**
   - 例外メッセージから `"duplicate"` または `"unique"` キーワードを検索
   - PostgreSQL エラーコード `23505` を検出する仕組みを追加
   - 該当する場合は「このカテゴリ名は既に使用されています。別の名前を入力してください。」というメッセージを返す

2. **例外クラスの検討**
   - `RepositoryException` に `isDuplicateKeyError` フラグを追加するか、新しい例外クラス `DuplicateKeyException` を作成
   - サービス層でこれをキャッチして、コントローラーに適切なエラーコードを返す

### レベル 2: ユーザーフレンドリーなダイアログ表示（推奨）

UNIQUE制約違反を検出した際に、専用のエラーダイアログを表示。

- ダイアログのアクション:
  - 「再度入力する」: ダイアログを閉じず、テキストフィールドをクリアしてフォーカス
  - 「キャンセル」: ダイアログを閉じる

## タスク分解

### 1. PostgreSQL エラーコード検出ロジックの追加

**ファイル**: `lib/core/utils/error_handler.dart`

```dart
// エラーメッセージから UNIQUE制約違反を検出するヘルパーメソッド
bool _isDuplicateKeyError(dynamic error) {
  if (error is RepositoryException) {
    final String message = error.toString();
    // PostgreSQL UNIQUE制約違反
    if (message.contains('23505') || 
        message.contains('duplicate key value') ||
        message.contains('unique constraint')) {
      return true;
    }
  }
  return false;
}

// 重複エラー検出時の返すメッセージ
String _getDuplicateKeyMessage() => 
    'このカテゴリ名は既に使用されています。別の名前を入力してください。';
```

### 2. ErrorHandler の handleError() メソッド拡張

**ファイル**: `lib/core/utils/error_handler.dart`

```dart
// 変更前（17～25行目付近）
String handleError(dynamic error, {String? fallbackMessage}) {
  LoggerBinding.instance.e("Handling error", error: error);

  if (error is RepositoryException) {
    return error.userMessage;
  }

  if (error is BaseContextException) {
    return fallbackMessage ?? "処理中にエラーが発生しました。";
  }

  return fallbackMessage ?? "予期しないエラーが発生しました。もう一度お試しください。";
}

// 変更後
String handleError(dynamic error, {String? fallbackMessage}) {
  LoggerBinding.instance.e("Handling error", error: error);

  if (error is RepositoryException) {
    // UNIQUE制約違反を特別に検出
    if (_isDuplicateKeyError(error)) {
      return _getDuplicateKeyMessage();
    }
    return error.userMessage;
  }

  if (error is BaseContextException) {
    return fallbackMessage ?? "処理中にエラーが発生しました。";
  }

  return fallbackMessage ?? "予期しないエラーが発生しました。もう一度お試しください。";
}
```

### 3. コントローラー側でのエラーハンドリング強化（任意）

**ファイル**: `lib/features/inventory/presentation/controllers/inventory_management_controller.dart`

オプション: コントローラーレベルで UNIQUE制約違反を更に詳細に処理する場合。

```dart
// createCategory() メソッド内
try {
  await _inventoryService.createMaterialCategory(
    MaterialCategory(name: trimmedName, displayOrder: nextDisplayOrder),
  );
  await loadInventory();
  return null;
} catch (error) {
  final String message = ErrorHandler.instance.handleError(error);
  // さらに詳細な処理（例: エラーダイアログの表示）が必要な場合
  // ここで特定のエラータイプを判定し、UI を分岐
  state = state.copyWith(isLoading: false, errorMessage: message);
  return message;
}
```

### 4. UI 側でのダイアログ表示改善

**ファイル**: `lib/features/inventory/presentation/pages/inventory_management_page.dart`

カテゴリ追加ダイアログ内で、エラーメッセージを表示する際により分かりやすいダイアログを表示。

```dart
// 現在の実装（323～344行目付近）
if (errorMessage != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorMessage)),
  );
  setDialogState(() => isSaving = false);
  return;
}

// 改善案: ダイアログ内エラー表示の活用
if (errorMessage != null) {
  // 重複エラーの場合は、テキストフィールドをクリアしてフォーカスを返す
  if (errorMessage.contains("既に使用されています")) {
    nameController.clear();
    nameController.text = ""; // ← クリア後に UI を更新
    // またはダイアログ内に TextField の下部に赤いエラーメッセージを表示
    setDialogState(() {
      isSaving = false;
      // エラーメッセージをダイアログ内に表示するために状態変数に保持
    });
    return;
  }
  
  // その他のエラーは SnackBar で表示
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorMessage)),
  );
  setDialogState(() => isSaving = false);
}
```

### 5. メニュー管理画面への同様の実装

**ファイル**: `lib/features/menu/presentation/pages/menu_management_page.dart`

同様のカテゴリ作成ダイアログについても、同じエラーハンドリングを適用。

### 6. 静的解析・フォーマッティング

- `flutter analyze` を実行し、エラーがないことを確認
- `dart format` を実行し、コード形式を整える

### 7. ユニットテスト追加（推奨）

**ファイル**: `test/core/utils/error_handler_test.dart`（新規作成）、またはテスト追加

テスト例:
```dart
test('handleError should detect duplicate key error', () {
  // Given
  final RepositoryException error = RepositoryException(
    message: 'Error: duplicate key value violates unique constraint',
    userMessage: 'An error occurred',
  );
  
  // When
  final String result = ErrorHandler.instance.handleError(error);
  
  // Then
  expect(result, contains('既に使用されています'));
});
```

## 検証計画

### UI 検証チェックリスト
- [ ] 在庫管理画面でカテゴリを追加
- [ ] 既存のカテゴリと同じ名前を入力して保存
- [ ] 「このカテゴリ名は既に使用されています」というメッセージが表示される
- [ ] メニュー管理画面でも同様の確認
- [ ] エラーメッセージが表示されても、テキストフィールドはクリアされず再入力が可能
- [ ] 「キャンセル」でダイアログを閉じられる
- [ ] その他のエラー（ネットワークエラーなど）も適切に表示される

### コード検証チェックリスト
- [ ] `flutter analyze` にエラーがない
- [ ] `dart format` で形式が統一されている
- [ ] `ErrorHandler._isDuplicateKeyError()` が UNIQUE制約違反を正しく検出している
- [ ] 既存のエラーハンドリングに影響がない

## 成果物

- `lib/core/utils/error_handler.dart` の修正版
- `lib/features/inventory/presentation/pages/inventory_management_page.dart` の修正版（オプション）
- `lib/features/menu/presentation/pages/menu_management_page.dart` の修正版（オプション）
- （推奨）`test/core/utils/error_handler_test.dart` の新規作成またはテスト追加

## リスク・注意事項

- **エラーコード検出の脆弱性**: PostgreSQL のエラーコードやメッセージフォーマットが将来変更される可能性
  - ⇒ Supabase ドキュメントを常時参照し、エラー検出ロジックをメンテナンス
- **多言語対応**: 将来多言語に対応する場合、エラーメッセージも言語別リソースとして管理すべき
  - ⇒ 現在は日本語のみなので問題なし
- **ユーザーの重複チェック**: バックエンド側での検出より先に、クライアント側での重複チェック（`state.categoryEntities` の参照）が実装されている
  - ⇒ クライアント側チェックで 95% がカバーされるが、マルチユーザー環境でのレアケースに対応

## 関連タスク

- **ID**: Inventory-Enhancement-40
- **Priority**: P1
- **Size**: M
- **Goal**: メニュー・在庫カテゴリの UNIQUE制約違反エラーが適切に処理・表示される
- **関連機能**: カテゴリ管理、エラーハンドリング、UI/UX 改善

## スケジュール目安

- エラー検出ロジック実装: 30分
- ErrorHandler 修正: 15分
- UI 改善（ダイアログ）: 20分
- テスト・検証: 30分
- **合計**: 1.5 時間程度

## 参考資料

- **PostgreSQL エラーコード**: https://www.postgresql.org/docs/current/errcodes-appendix.html
- **Supabase エラーハンドリング**: https://supabase.com/docs
- **既存エラーハンドリング**: `lib/core/utils/error_handler.dart`
- **例外クラス**: `lib/core/constants/exceptions/exceptions.dart`
- **サービス層実装**: `lib/features/inventory/services/material_management_service.dart`

