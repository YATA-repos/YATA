# メニュー管理 リフレッシュ導線統合計画（2025-10-04）

## 背景
- TODOリストの「Menu-Bugfix-2」はメニュー管理画面のヘッダーにリフレッシュボタンを復帰させ、在庫・メニュー情報の即時再読込を再びトップバーから行えるようにするタスク。
- TODOリストの「Menu-Chore-1」はページ内に暫定的に配置されている "在庫状況を再取得" ボタンを削除し、導線をトップバーのリフレッシュボタンへ集約するタスク。
- 現在の実装ではトップバー右上（`YataAppTopBar.trailing`）が空で、ページ内の`MenuManagementHeader`に`YataIconLabelButton`が残置されているため、導線が分散しUIの一貫性が損なわれている。
- 今回の計画では2つのタスクを同時に進め、リフレッシュ導線をトップバーに統合しつつ冗長なボタンを整理する。

## スコープ
- 対象タスク: `Menu-Bugfix-2`, `Menu-Chore-1`
- 対象UI: `lib/features/menu/presentation/pages/menu_management_page.dart`, `lib/features/menu/presentation/widgets/menu_management_header.dart`
- 対象コンポーネント: `YataAppTopBar`, `YataIconButton`, `YataIconLabelButton`
- 対象ステート: `MenuManagementController`, `MenuManagementState`

## 現状整理
1. `MenuManagementPage`では`YataAppTopBar`の`trailing`が未設定のため、リフレッシュ操作が表示されない。
2. ページ内部の`MenuManagementHeader`に仮の`YataIconLabelButton`（"在庫状況を再取得"）があり、`onRefreshAvailability`で在庫可用性のみ再計算している。
3. フルリフレッシュを行うには`MenuManagementController.refreshAll()`を呼ぶ必要があるが、現在はトップバーから実行できない。
4. `_refreshCompleter`と`state.isLoading`による多重実行防止ロジックが存在するため、トップバーに導線を追加する際も一貫して利用する必要がある。

## 達成ゴール
- **Menu-Bugfix-2**: トップバー右上にリフレッシュボタンを設置し、全データ再読込 (`refreshAll`) を安全に実行できる。実行中はボタン無効化を含むユーザー通知が機能する。
- **Menu-Chore-1**: ページ内の"在庫状況を再取得"ボタンと関連コードを削除し、重複導線を解消する。削除後も在庫可用性再計算はトップバー導線経由で成立していることを確認する。

## 実装方針
1. **共通ハンドラの整備**
   - `MenuManagementPage`に `_handleRefreshAll()`（仮称）を新設し、`_controller.refreshAll()`の呼び出しと`_refreshCompleter`管理を一箇所に集約する。
   - 既存の在庫再取得ボタンが利用しているロジックを流用しつつ、全データ再読込に統一する。
2. **トップバーUIの追加**
   - `YataAppTopBar`の`trailing`へ`YataIconButton`（`Icons.refresh_outlined`）を追加し、ツールチップと`Semantics`ラベルを設定。
   - ボタンの`onPressed`は`state.isLoading`や`_refreshCompleter.isCompleted`に応じて無効化し、多重実行を防止。
   - インジケータ表示（ローディングスピナー等）が既存の`MenuManagementHeader`と整合するようにする。
3. **画面内ボタンの撤去**
   - `MenuManagementHeader`から"在庫状況を再取得"ボタンと関連する`onRefreshAvailability`の引数を削除。
   - ボタン撤去に伴い余白やFlex配置が崩れないか調整。
   - `MenuManagementPage`側のプロパティ／引数も整理し、不要な依存を排除。
4. **状態更新ロジックの再確認**
   - `refreshAll()`完了後に在庫可用性が再計算されるか確認し、必要ならサービス層呼び出し順を明示的に調整。
   - 今後の拡張（モーダル化など）に備えて、トップバー導線の再利用性を意識したメソッド設計を行う。

## 作業ステップ
1. 類似ページ（例: `InventoryManagementPage`）での`YataAppTopBar.trailing`実装を確認し、UI・アクセシビリティ要件を抽出。
2. `MenuManagementPage`に共通ハンドラを追加し、既存ロジックを`refreshAll`に統一。
3. トップバーに`YataIconButton`を配置し、状態に応じて活性/非活性を切り替える。
4. `MenuManagementHeader`から"在庫状況を再取得"ボタンを削除し、余ったスペースを調整。
5. `flutter analyze`と`flutter test`（該当範囲）で静的解析・回帰テストを実行。
6. 手動でメニュー管理画面を確認し、トップバーのみでリフレッシュ導線が完結すること、ローディング表示が意図通りであることを検証。

## 確認ポイント
- トップバーのリフレッシュボタンが常時表示され、押下時に全データ再読込が行われる。
- リフレッシュ中にボタンが無効化され、完了後に復帰する。
- ページ内の"在庫状況を再取得"ボタンが削除され、UIの崩れが発生しない。
- 既存の状態管理ロジック（`MenuManagementController`）が想定通り動作し、在庫可用性情報が最新化される。

## リスクと緩和策
- **多重リロード**: `_refreshCompleter`の扱いを誤ると多重実行が発生する恐れ → 共通ハンドラを介して制御し、`Completer`の初期化タイミングを明示的に管理。
- **UI崩れ**: ボタン削除後の`MenuManagementHeader`レイアウトが崩れる可能性 → レイアウトを再計算し、余白やFlex設定を調整。
- **権限／ネットワークリトライ**: リフレッシュ実行頻度が上がることでエラー頻度が顕在化する恐れ → 既存のエラーハンドリング（バナー、再試行ボタン）の動作を再確認し、必要に応じてメッセージを改善。

## 依存・フォローアップ
- 本計画完了後にトップバーへのアクション集約が完了するため、関連タスク（例: `Menu-Chore-1`以外のボタン整理）で整備しやすくなる。
- 将来的に詳細モーダル化や操作カラム整理（`Menu-Enhancement-5`, `Menu-Enhancement-7`）を行う際、トップバーからの導線を再利用する想定。