# メニュー管理 リフレッシュボタン復帰計画（2025-10-05）

## 背景
- TODO項目「Menu-Bugfix-2」のゴールは、メニュー管理画面のヘッダー（`YataAppTopBar`）から在庫・メニュー情報を即時再取得できる導線を復旧すること。
- 現在はトップバー右上にアクションが存在せず、ページ内の`MenuManagementHeader`に仮設ボタン（`在庫状況を再取得`）を配置している状態。
- 他ページ（例: 在庫管理画面 `lib/features/inventory/presentation/pages/inventory_management_page.dart`）ではトップバー右上に`YataIconButton`でリフレッシュを配置しており、一貫性の欠如がUX低下要因となっている。

## 現状整理
- `MenuManagementPage` (`lib/features/menu/presentation/pages/menu_management_page.dart`) の`YataAppTopBar`呼び出しでは`trailing`引数を未指定のため、右上アクション領域が空になっている。
- ページ下部の`MenuManagementHeader` (`lib/features/menu/presentation/widgets/menu_management_header.dart`) には`YataIconLabelButton`があり、`onRefreshAvailability`で在庫可用性のみを再計算している。
- 状態管理では`MenuManagementController.refreshAll()`が全データ再読込、`refreshAvailability()`が在庫可用性のみ再計算と役割分担されている。
- `_refreshCompleter`で連打抑制を行っているが、トップバー上の導線が無いためユーザは全体リロードを即時実行できない。

## 対応ゴール
1. トップバー右上にリフレッシュボタンを常設し、`refreshAll()`を実行できるようにする。
2. リフレッシュ中はボタンを無効化し、ロード状態が視覚的に分かるよう既存のプログレス表示と整合させる。
3. 既存の`在庫状況を再取得`ボタンは依存タスク（Menu-Chore-1）で除去予定のため、本対応では共存させつつ競合しないようにする。

## 対応方針
1. **UI配置**
   - `YataAppTopBar`呼び出しに`trailing`リストを追加し、`YataIconButton`（`Icons.refresh_outlined`）でリフレッシュ導線を復帰。
   - 既存ページに倣いツールチップを設定し、操作意図を明確化。
2. **ハンドラ統合**
   - `_controller.refreshAll()`を発火させる専用メソッドをページ側に用意し、トップバー／ヘッダ双方で使えるよう切り出し。
   - 実行中フラグとして`state.isLoading`と`_refreshCompleter`を併用し、多重実行を防止。
3. **アクセシビリティ**
   - キーボード／フォーカス操作時もボタンが利用できるよう標準コンポーネントを活用。
   - アイコンのみのため、ツールチップと`Semantics`ラベル（必要に応じて）を付与することを検討。
4. **レイアウト検証**
   - ウィンドウ幅が狭い場合でもナビゲーションと干渉しないか確認し、必要に応じて`trailing`のアイテム順やスペースを調整。

## 作業タスク
1. **比較調査**: 在庫管理ページなど既存実装を確認し、`YataAppTopBar`の`trailing`利用パターンを整理。
2. **イベントハンドラ整備**: `MenuManagementPage`にトップバー用`_handleRefreshAll`（仮）を新設し、共通で使用するロジックへ集約。
3. **UI追加**: `YataAppTopBar`の引数に`trailing`を追加し、`YataIconButton`でリフレッシュアクションを登録。
4. **状態連携調整**: ボタンの`onPressed`制御に`state.isLoading`および`_refreshCompleter`の状態を反映。
5. **コード整合性確認**: `flutter analyze`の実行、既存テストへの影響確認。必要であれば軽微なユニットテストやWidgetテストの追加を検討。
6. **追跡事項の整理**: `Menu-Chore-1`でのボタン削除に備え、本タスクでの変更点・依存をTODOやドキュメントに明記。

## 検証計画
- `flutter analyze` を実行し、リント・解析エラーがないことを確認。
- メニュー管理画面を起動し、以下を手動確認:
  - トップバー右上のリフレッシュボタンが表示される。
  - リフレッシュ中はボタンが無効化され、完了後に再度押下可能になる。
  - 既存の`在庫状況を再取得`ボタンと同時利用しても競合や二重処理が発生しない。
  - エラー発生時のバナー表示・再試行動作が維持される。

## リスクと緩和策
- **リフレッシュ多重実行**: `_refreshCompleter`の扱いを誤ると競合が再発する恐れ → 共通メソッド化し、ガード処理を一箇所で管理。
- **UI崩れ**: トップバーの横幅制約でナビ項目が詰まる可能性 → 小画面レイアウトでの検証と、必要ならアイコンサイズ・スペーシング調整。
- **権限エラー**: リロード時に発生するエラーがトップバーの導線復帰で顕在化する可能性 → 既存の`ErrorBanner`による再試行導線を確認し、必要ならメッセージ改善を検討。

## 関連タスク
- `Menu-Chore-1`（在庫状況ボタン削除）: 本タスク完了後に着手することで、導線重複が解消される。
- `Menu-Bugfix-1`（設定導線統一）: 同じトップバー領域を利用するため、導線配置・ボタン順の兼ね合いを調整する。

