# 設定機能実装計画草案 (2025-10-10)

## 1. 背景と目的

- 現状の `SettingsPage` はモック UI のみで、実際のアクションや状態管理は未実装。
- 屋台運営の現場で必要となる運用系オプション（ログアウト、開発支援、税率変更、ログ保管先の調整）をアプリ内で完結できるようにする。
- 本草案では、実装対象範囲・責務分担・段階的な開発ステップを整理し、実装フェーズで迷わないための共通認識を確立する。

## 2. 機能要件整理

| 要件 | 詳細 | 補足 |
| --- | --- | --- |
| ログアウト | 現在の認証セッションを終了する。複数端末サインアウト（全端末）オプションは任意。 | 既存の `AuthService.signOut` を呼び出し、UI で処理中インジケーターと成功/失敗通知を表示。 |
| デバッグモード切り替え | (a) グローバルログレベルの選択、(b) アプリ内デバッグフラグの ON/OFF。 | 既存の `logger.dart` の `setGlobalLevel`、`RuntimeOverrides` を活用。 |
| 消費税率切り替え | 税率 (例: 8% / 10%) を指定し、注文計算など全体に反映。 | `OrderCalculationService` および `OrderManagementState.taxRate` に連動させる。 |
| ログ保存ディレクトリ変更 | ログ出力フォルダを選択/リセットできる。 | `LogConfigHub` を通じて動的適用。`file_picker` を利用予定。 |

## 3. 現状把握

- UI: `lib/features/settings/presentation/pages/settings_page.dart` にモック UI が存在。
- 認証: `AuthController` (`features/auth`) でサインアウト処理が既に提供されている。
- ログ: `lib/infra/logging/` 配下に `LogConfigHub`, `logger.dart`, `log_runtime_config.dart` があり、ランタイムで設定を変更できる仕組みが整っている。
- ランタイムフラグ: `lib/infra/config/runtime_overrides.dart` が動的なフラグ管理を提供。
- 永続化: プロジェクトには `shared_preferences` と `path_provider`, `file_picker` が依存関係として追加済み。
- 税率: `OrderManagementState` の `taxRate` フィールド、および `OrderCalculationService.calculateTaxAmount` が税計算を担当。現状は固定値で初期化される。

## 4. アーキテクチャ方針

### 4.1 ドメインモデル案

```mermaid
erDiagram
    AppSettings ||--|| DebugOptions : contains
    AppSettings {
      double taxRate
      String? logDirectory
      DebugOptions debug
    }
    DebugOptions {
      bool developerMode
      LogLevel globalLogLevel
    }
```

- `AppSettings`: UI/サービス間で扱う単一の設定モデル。リポジトリや永続化層とやり取りする際の基本単位とする。
- `DebugOptions`: デバッグ関連の設定を内包するサブモデル。

### 4.2 レイヤー別責務

| レイヤー | 役割 |
| --- | --- |
| UI (`SettingsPage`, `SettingsSections`) | 設定入力・確認・ユーザー操作。Riverpod Provider から状態を購読し、非同期処理の進捗を表示。 |
| Service (`SettingsService`) | UI と Repository/既存サービス間の調停。設定更新時に関連システム（Logger, RuntimeOverrides, Order 計算等）へ反映。 |
| Repository (`SettingsRepository`) | 永続化層（SharedPreferences / ファイル）読み書きとデフォルト値解決。 |
| Infra (`SettingsLocalDataSource`) | `SharedPreferences` ラッパー、`path_provider` による既定ログディレクトリの解決、`file_picker` を用いたフォルダ選択。 |

### 4.3 状態管理

- `settingsControllerProvider` (AsyncNotifier): `SettingsService` を呼び出し、`AsyncValue<AppSettings>` を公開。
- `settingsFormProvider` (StateNotifier): UI 側での入力中の変更（楽観的 UI）を扱い、永続化成功時に `settingsController` を更新。
- 既存の `OrderManagementController` 等は `ref.listen<AppSettings>` で税率変更をフックし、内部状態を更新する。

## 5. 機能別詳細計画

### 5.1 ログアウト

- UI: 「ログアウト」ボタン + 二段階確認ダイアログ（誤タップ対策）。
- 操作フロー:
  1. ボタン押下で `settingsController.signOut()` を呼ぶ。
  2. Service から `AuthController` / `AuthService` に委譲。
  3. 成功時は `GoRouter` で `/auth` へ遷移、共有状態をクリア。
  4. 失敗時は Snackbar で通知（ログにもエラー出力）。
- オプション: 「すべての端末からサインアウト」チェックボックスをダイアログに配置。

### 5.2 デバッグモード / ログレベル

- UI: スイッチとドロップダウン。
  - 「デベロッパーモード」トグル → `RuntimeOverrides.setBool("debug.developerMode")` を更新。
  - 「ログレベル」選択 → `LogLevel` enum を `DropdownButton` で提示。
- 反映:
  - `SettingsService` が `logger.setGlobalLevel(level)` を呼び、必要に応じてタグレベルも初期化。
  - `RuntimeOverrides` によるフラグ変更を `StreamProvider` で監視し、デバッグ用途の UI (例: トレース表示) と連動させる。
  - リリースビルドでは、UX 上の意図しない変更を防ぐために警告ダイアログやロールバックボタンを配置。

### 5.3 消費税率

- 税率候補: 0.08 (軽減) / 0.10 (標準) / カスタム入力 (0.00〜0.20).
- `SettingsService` が税率更新時に:
  - 永続化層を更新。
  - `OrderCalculationService` に新しいデフォルト税率を渡す（サービスに新しい setter/DI を追加）。
  - `OrderManagementController` 等が `ref.listen` でイベントを受け取り、`state.copyWith(taxRate: newRate)` を実行。
- 計算系のユニットテストを更新し複数税率で検証。

### 5.4 ログ保存ディレクトリ

- UI: カレントディレクトリ表示 + 「変更」ボタン + 「デフォルトに戻す」ボタン。
- ディレクトリ選択:
  - `file_picker` の `getDirectoryPath` を使用。
  - Windows/Linux の権限差を考慮し、アクセス不可時はエラーハンドリング。
- 適用:
  - `SettingsService` が `updateLoggerConfig` に `LogConfig.applyTo` を渡し、`fileDirPath` を更新。
  - リセット時は `path_provider` で取得する既定パス（例: `getApplicationSupportDirectory()` 内の `logs/`）に戻す。
- 変更後は Snackbar で結果を通知し、ログ再オープンに失敗した場合はロールバック。

## 6. 永続化・同期戦略

- `SettingsRepository` は以下のキーで `SharedPreferences` を使用: `settings.taxRate`, `settings.logLevel`, `settings.debugMode`, `settings.logDir`。
- 初期ロード時:
  1. `SharedPreferences` から値を読み込み。
  2. 値が存在しない場合は `LogConfig.defaults` やアプリ内定数からデフォルト生成。
  3. 読み込んだ設定を `SettingsService` 経由で適用（ログ・税率等）。
- 将来的な要件に備え、`SettingsRepository` は JSON でまとめて保存する実装に拡張可能な形にしておく。
- 設定変更イベントは `StreamController<AppSettings>` で配信し、他サービスが購読できるようにする。

## 7. UI 設計メモ

- ページを 4 セクションに区切り、`YataSectionCard` (既存パターン) を利用。
  1. アカウント (ログアウト)
  2. デバッグ (トグル + ログレベル)
  3. 税率 (ラジオボタン + 数値入力)
  4. ログ (ディレクトリ情報)
- PC 前提 UI のため、フォーム幅は 480px 程度を維持し、`ResponsiveLayout` による調整は後続で検討。
- 非同期操作は `AsyncValue` と `YataPrimaryButton` の `isLoading` プロップを使用してフィードバックを統一。

## 8. 開発ステップ案

1. **基盤整備**
   - `SettingsRepository` / `SettingsService` / `SettingsController` の骨格を作成。
   - 既存ロガー・オーダーサービスとのインターフェース (setter / event) を追加。
2. **デバッグ/ログ設定対応**
   - ログレベルとログディレクトリ変更機能を Service から実行可能にする。
   - ユニットテストで `logger.setGlobalLevel` と `updateLoggerConfig` の呼び出しを検証。
3. **税率切り替え対応**
   - `OrderCalculationService` へ税率 DI を導入し、`OrderManagementController` が設定変更を監視する。
   - 計算系テストを拡張。
4. **UI 実装**
   - 各セクションのウィジェットを構築し、Service 呼び出しを繋ぎ込む。
   - エラーハンドリングとスナックバー表示を実装。
5. **仕上げ**
   - 結合テスト (Widget / Integration) を追加。
   - ドキュメント (`docs/guide/` 等) を更新し、QA チェックリストを作成。

## 9. テスト計画

- **ユニットテスト**: `SettingsService` の各メソッド、税率計算、ログディレクトリ変更のロールバック。
- **Widget テスト**: 設定ページ上の操作 (トグル、ドロップダウン、ディレクトリ選択) が正しい Service 呼び出しを行うか。
- **統合テスト**: 税率変更後に `OrderManagementPage` で小計→税額→合計が反映されること。
- **回帰テスト**: ログアウト後の再ログインフロー、ログディレクトリ変更が他プラットフォームで問題なく作動するか。

## 10. リスクとオープン課題

1. **ログディレクトリ権限**: Windows の UAC や Linux の権限で書き込み失敗するケース → 失敗時のフォールバックとユーザー通知が必要。
2. **税率変更の反映漏れ**: `OrderCalculationService` 以外の税率参照箇所が見落とされている可能性。参照箇所の棚卸しが必要。
3. **デバッグモードの意味付け**: フラグ ON でどこまで機能を開放するか (例: Dev メニュー、BETA 機能) を別途定義する必要がある。
4. **設定保存の競合**: 複数ウィンドウ対応時の整合性。今後マルチウィンドウをサポートする場合は `SharedPreferences` 以外の仕組みも検討。
5. **ログサイズ肥大化**: 低レベル (trace/debug) を有効にしたまま運用するとログ肥大が想定される。ローテーション設定を UI で触れるかは別議題とする。

## 11. 参考

- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/auth/services/auth_service.dart`
- `lib/infra/logging/logger.dart`, `log_runtime_config.dart`, `log_config.dart`
- `lib/infra/config/runtime_overrides.dart`
- `lib/features/order/presentation/controllers/order_management_state.dart`
- `lib/features/order/services/order/order_calculation_service.dart`
