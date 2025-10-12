# 設定機能本実装計画 (2025-10-10)

## 1. 背景
- `SettingsPage` はモック UI のままリリースされており、運用チームがアプリ内で基本設定を調整できない。
- ログアウトやデバッグ関連スイッチは都度開発者が Supabase/ログ設定を直接操作しており、手間とリスクが高い。
- 注文計算ロジックは税率を固定値で扱っているため、軽減税率や将来の税率変更へ柔軟に追従できない。
- ログの出力先が固定で、マシンごとのストレージ事情に応じた運用が難しい。

## 2. 目的
1. 設定ページから主要オペレーションを完結できるようにし、現場メンバーのセルフサービス性を高める。
2. デバッグ系オプションを UI から安全に制御できるようにし、開発/QA フローを効率化する。
3. 税率・ログディレクトリといった運用値をホットスワップ可能にし、将来の変更コストを最小化する。

## 3. スコープ
### 3.1 実装対象
- ログアウト操作
- デバッグモード ＆ ログレベル切替
- 消費税率の指定/保存/即時反映
- ログ保存先ディレクトリの選択・リセット
- 設定値の永続化・アプリ起動時読み込み・他レイヤーへの反映
- UI/UX: セクション分割・状態表示・非同期処理フィードバック

### 3.2 スコープ外
- multi-tenant サポートやユーザーロール別の設定可否制御
- Supabase Realtime やリモート設定との統合
- ログローテーション UI・詳細ロガー設定 (別計画で検討)
- 税率に紐づく帳票/レポート出力 (別計画)

## 4. 成果物
- `AppSettings` ドメインモデルと関連サービス/リポジトリ/データソース
- Riverpod プロバイダ群 (`settingsControllerProvider`, `settingsFormProvider` 等)
- 更新済み `SettingsPage` UI コンポーネント
- 単体/ウィジェット/統合テスト
- ドキュメント更新 (`docs/guide/`, `docs/reference/`, リリースノート草案)

## 5. ワークストリーム詳細

| WS | 概要 | 主要成果物 | 依存 |
| --- | --- | --- | --- |
| WS-A | アプリ設定インフラ整備 | `AppSettings`, `SettingsRepository`, `SettingsService` | SharedPreferences, logger, RuntimeOverrides |
| WS-B | アカウント操作 (ログアウト) | UI セクション、`AuthService.signOut` 連携 | WS-A (UI レイアウト共通化) |
| WS-C | デバッグオプション | ログレベル/開発者モード制御と通知 | WS-A (設定適用パイプライン) |
| WS-D | 税率管理 | 税率保存・注文系サービス反映 | Order services、WS-A |
| WS-E | ログ保存ディレクトリ | ディレクトリピッカー、`LogConfig` 適用 | file_picker、logger |

### WS-A: 設定インフラ
- **現状**: 設定値を一元管理する仕組みがなく、個別サービスで固定値。
- **To-Be**:
  - `AppSettings` と `DebugOptions` のモデルを導入。
  - `SettingsRepository` が `SharedPreferences` を利用し、`SettingsLocalDataSource` と `SettingsMapper` で変換を行う。
  - `SettingsService` が読込/保存/適用を担当。`StreamController<AppSettings>` を公開し、他サービスが購読可能にする。
  - アプリ起動時 (`bootstrap` フロー) に `SettingsService.loadAndApply()` を実行。
- **タスク**:
  1. `lib/features/settings/domain/app_settings.dart` 追加 (immutable, copyWith, json シリアライズ不要)。
  2. `SettingsRepository` を `lib/features/settings/data/settings_repository.dart` に追加。
  3. `SettingsService` (`lib/features/settings/services/settings_service.dart`) 作成。
  4. Riverpod プロバイダ (`settingsControllerProvider`, `settingsUpdatesProvider`) 定義。
  5. 初期ロードを `main.dart` で呼び出すフローを組み込み。
- **Acceptance**:
  - `SettingsService.load()` が永続化済みデータ/デフォルト値を正しく返す。
  - `SettingsService.watch()` を購読すると更新がリアルタイム反映される。

### WS-B: ログアウトセクション
- **UI**: `YataSectionCard` で「アカウント設定」。主要要素:
  - ログアウトボタン (primary)。
  - 「全端末からサインアウト」のチェックボックス。
  - 状態 (`AsyncValue`) に応じたローディング表示。
- **サービス連携**:
  - `SettingsService.signOut()` が `AuthService.signOut` を呼び、例外で `AppFailure` を返却。
  - 成功時に `GoRouter` で `/auth` へ遷移。`settingsController` はローカル状態をリセット。
- **テスト**:
  - `SettingsService` モックで成功/失敗ケースを検証する Widget テスト。
  - `AuthService.signOut` 呼び出しパスのユニットテスト。

### WS-C: デバッグモード & ログレベル
- **UI**:
  - `SwitchListTile` でデベロッパーモードのトグル。
  - `DropdownButton<LogLevel>` で `trace`〜`fatal` を選択可能に。
  - 現在のログレベル/適用結果を表示するサブテキスト (`AsyncValue` から `AppSettings.debug.globalLogLevel` を表示)。
- **適用ロジック**:
  - `SettingsService.updateDebugOptions(DebugOptions next)` が `RuntimeOverrides` と `log.setGlobalLevel` を同期。
  - 適用失敗時 (例: `logger` が例外) にロールバック。
  - リリースビルドでトグル操作時は警告ダイアログを挟む (ビルドフラグで制御)。
- **連携対象**:
  - 既存ログ関連の計画 (`docs/plan/logging/impl_plan_overview.md`) に合わせ、タグレベルの扱いなどを擦り合わせる。
- **テスト**:
  - `SettingsService.updateDebugOptions` のモック logger を用いたユニットテスト。
  - UI 側で `LogLevel.debug` → `LogLevel.warn` に切り替わる際の動作テスト。

### WS-D: 消費税率管理
- **要件**:
  - プリセット (8%, 10%) + カスタム入力 (0〜20% 上限) + 小数表示。
  - 保存時に `OrderCalculationService` 等へ即時反映。
- **設計**:
  - `AppSettings` に `double taxRate`。
  - `OrderCalculationService` に `setBaseTaxRate(double)` を追加。DI 経由で `SettingsService.watch()` を購読し、変更時に更新。
  - `OrderManagementController` は設定変更を `ref.listen(appSettingsProvider)` で受け、`state.copyWith(taxRate: newRate)`。
- **移行ステップ**:
  1. 既存の固定値 (0.08, 0.10) を `AppSettings` から注入する形に修正。
  2. 設定ページからの更新で `OrderManagementState` 反映と計算リフレッシュを行う。
  3. テスト資産 (`OrderCalculationServiceTest`) を税率パラメータ対応に更新。
- **検証**:
  - 税率変更後の注文合計が即座に更新される Widget テスト。
  - カスタム税率 (例: 7.5%) が丸め処理含め期待通りに計算されるユニットテスト。

### WS-E: ログ保存ディレクトリ
- **UI**:
  - 現在のディレクトリパス表示 (省略表記 + `Tooltip` でフルパス)。
  - 「変更」ボタン → `FilePicker.platform.getDirectoryPath` を呼び出し。
  - 「デフォルトに戻す」ボタン → `path_provider` 由来の初期パスへ復帰。
- **ロジック**:
  - `SettingsService.updateLogDirectory(String? path)` が `LogConfigHub` へ `copyWith(fileDirPath: path ?? defaultPath)` で適用。
  - 失敗時は元のディレクトリにロールバックし、通知。
  - Windows のパス区切り/権限エラーを考慮し、`try/catch` + ダイアログで扱う。
- **テスト**:
  - `LogConfigHub` をモックしたユニットテスト。
  - デフォルト復帰ボタン押下で `null` → 既定パスに戻る動作の Widget テスト。

## 6. 依存関係と調整事項
- `AuthService` / `order` サービス群 / `logger` との API 整合性確認。
- Windows/Android のファイルアクセス権限。Android 対応は別チケット (ストレージスコープ調査) を起票。
- Doc チームと連携し、運用マニュアルの更新タイミングを調整。

## 7. 実装フェーズとマイルストーン

| フェーズ | 期間目安 | 完了条件 |
| --- | --- | --- |
| P1: 基盤整備 (WS-A) | 2 日 | 設定読み書き/適用が動作し、暫定 UI から確認できる |
| P2: デバッグ & ログ整備 (WS-B/C/E) | 3 日 | ログアウト・デバッグ・ログディレクトリ UI が Service 経由で動作、主要テスト追加 |
| P3: 税率統合 (WS-D) | 2〜3 日 | 税率変更が注文計算/UI に即時反映し、既存テストが更新済み |
| P4: 仕上げ & QA | 2 日 | 受入テスト完了、ドキュメント整備、ハンドオフ準備 |

> 総工数目安: 9〜10 人日 (1 名フルタイム想定)。フェーズ間にレビュー期間 (0.5 日/フェーズ) を確保。

## 8. テスト戦略
- **ユニットテスト**: `SettingsService`, 税率計算, ログディレクトリ適用, デバッグフラグ。
- **Widget テスト**: 設定 UI の主要操作 (トグル, ドロップダウン, ディレクトリ選択ダイアログモック)。
- **統合テスト**: 税率変更 → 注文作成フロー、ログアウト → 再ログインフロー。
- **手動チェックリスト**:
  - Windows 端末でのディレクトリ変更 GUI 確認。
  - デベロッパーモード ON 時のログ出力レベル、OFF に戻した際の挙動。
  - ログアウト後に `settingsController` が再初期化されること。

## 9. ロールアウトとドキュメント
1. `dev` ブランチで段階的にマージ。P1 完了後に中間レビュー。
2. QA チームによるスモークテスト → 問題なければ `main` へ向けたリリースブランチ作成。
3. ドキュメント更新:
   - `docs/guide/settings.md` (新規) で設定画面操作手順を記載。
   - リリースノートに新機能を追記。運用チームへ展開。

## 10. リスクと対策
| リスク | 説明 | 対応策 |
| --- | --- | --- |
| 永続化不整合 | SharedPreferences 読込/書込失敗やフォーマット変更 | バージョン管理フィールドを追加し、破損時にデフォルトへフォールバック。ログ出力で通知。 |
| 設定競合 | 複数インスタンス (例: Windows マルチウィンドウ) から同時更新 | 単一インスタンス運用を前提とし、将来必要なら IPC 連携計画を別途立案。 |
| 税率反映漏れ | 既存コードで税率を直接指定している箇所が残る | `taxRate` 検索レビューを実施し、チェックリスト化。CI に静的分析ルール (todo: lint) を追加検討。 |
| ログ適用失敗 | ディレクトリ権限エラーやローテーション停止 | 適用前に書込みテストを実行し、失敗時にロールバック + ユーザー通知。 |
| UX 複雑化 | 設定項目が多くなり UI が煩雑になる | セクション分割と説明テキストで整理。将来的なグルーピングの余地を残す。 |

## 11. オープン課題
- Android でのディレクトリ選択: SAF (Storage Access Framework) が必要か。対応が複雑な場合は今回 Windows/Mac/Linux のみサポートに絞る。
- デベロッパーモード ON 時に解放する機能 (例: トレースオーバーレイ) の範囲定義。今後の `RuntimeOverrides` 利用方針を整理。
- 設定変更を Supabase 側に同期する要件が将来発生するか (多店舗運用)。必要なら設定バックアップ機能を別計画化。

---

### 参考資料
- `docs/draft/settings_feature_implementation_plan.md`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/auth/services/auth_service.dart`
- `lib/infra/logging/logger.dart`, `log_runtime_config.dart`, `log_config.dart`
- `lib/infra/config/runtime_overrides.dart`
- `lib/features/order/services/order/order_calculation_service.dart`
- `docs/plan/logging/impl_plan_overview.md`
