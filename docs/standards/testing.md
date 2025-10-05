# Testing Standards

Status: Draft (2025-10-05)

## 基本方針

- サービス層・ユースケース層では副作用やロギングを含む振る舞いをユニットテストで検証する。
- Riverpod などの DI を利用する場合は、テスト内で `ProviderContainer` を明示的に構築し、副作用 (ログ・イベント) をフックする。
- テストユーティリティは `test/support/` 配下に集約し、フィーチャー横断で再利用する。

## ログ検証ベストプラクティス

### 目的

- 重要フローで想定されたレベル・メッセージでログが出力されることを保証する。
- 意図しない大量出力やメッセージ欠落の回帰を CI で早期検知する。

### 推奨ユーティリティ

| ユーティリティ | 主な用途 | 補足 |
| --- | --- | --- |
| `FakeLogger` | 非同期処理を含むロギングの捕捉・待機 | `waitFor` で条件付き待機が可能。`entries` は読み取り専用ビュー。 |
| `SpyLogger` | 実ロガーへフォワードしつつテストで検証 | 委譲先を指定しない場合は記録のみ行う。 |
| `log_expectations.dart` | ログ検証アサーション (`expectLog` / `expectNoLog`) | `where` 句で詳細条件を追加できる。 |

### 使用例

```dart
final FakeLogger logger = FakeLogger();

final CapturedLog debugLog = await expectLog(
  logger,
  level: Level.debug,
  tag: "OrderCalculationService",
  messageContains: "Order total calculated",
);

await expectNoLog(
  logger,
  where: (CapturedLog entry) => entry.level == Level.error,
);
```

- `expectLog` は要求条件に一致するログが出力されるまで待機し、`TimeoutException` で失敗する。
- `expectNoLog` は指定した条件のログが一定時間現れないことを確認する。追加で `where` を渡すとフィルタリングできる。

### 運用ルール

1. **テスト内で DI を経由してロガーを差し替える。** `LoggerBinding.register` を用いる場合は `ref.onDispose(LoggerBinding.clear)` を忘れない。
2. **ログ検証は最小限のメッセージ一致で行い、細かい文言は部分一致 (`messageContains`) を推奨。**
3. **例外ハンドリングのテストでは `errorWhere` でエラー型・メッセージを確認し、`stackTrace` が null でないこともセットで検証する。**
4. **大量ログを伴う処理では `logger.clear()` や `expectNoLog` を併用してノイズを抑制する。**

### スパイロガーの活用

- 実際の `LoggerContract` 実装へ書き込みつつ、テストで検証したい場合に `SpyLogger(delegate: realLogger)` を使用する。
- `SpyLogger` も `LogProbe` を実装しているため、`expectLog`/`expectNoLog` をそのまま利用可能。
- 連携先に負荷を掛けたくない場合は `delegate` を省略し、記録専用として扱う。

### タイムアウト調整

- デフォルトの待機時間は 200ms。非同期ストリームなどで遅延が見込まれる場合は `expectLog(..., timeout: Duration(seconds: 1))` のように延長する。
- テストが不安定になる場合は、処理完了イベントを待ってからログ検証を行うなど、待機条件を明確化する。

## 関連資料

- `docs/plan/logging/2025-10-05-logging-test-strategy-plan.md`
- `test/features/order/services/order_calculation_service_test.dart`
- `test/support/logging/`
