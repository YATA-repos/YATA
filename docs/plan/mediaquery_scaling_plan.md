# アプローチA: MediaQuery差し替えによるWindows UI縮小 実装計画

- 作成日: 2025-10-09
- 作成者: GitHub Copilot
- 対象ブランチ: `dev`
- 対象課題: Windows 版のみ UI 全体が高 DPI 設定により拡大して見える問題

## 1. ゴールと非ゴール
### ゴール
- Windows 実行時に `MediaQuery` を差し替え、論理 DPI を人工的に 1.0 近辺へ補正する。
- 主要画面（注文管理／在庫管理／注文履歴／売上分析／設定）が Linux 版と近い見た目になる。
- 縮小率を設定値として管理し、将来の微調整が簡単にできる状態にする。

### 非ゴール
- レイアウト自体のレスポンシブ最適化（縦積み切替等）は対象外。
- macOS や Linux の表示調整は行わない。
- DPI 起因のフォントぼやけやアクセシビリティ問題の抜本的解決までは扱わない。

## 2. 現状整理
- `lib/app/app.dart` の `YataApp` は `MaterialApp.router` を返却しており、ビルダー介入ポイントが存在しない。
- `YataPageContainer` は `maxWidth=1280` を固定、レイアウトはデスクトップ前提。
- Windows ランナー (`windows/runner/win32_window.cpp`) はモニター DPI を反映しているため、`MediaQuery.of(context).devicePixelRatio` は 1.2〜1.5 などの値になる。
- アプリ全体で `devicePixelRatio` や `textScaler` を書き換えていないため、UI は OS DPI に完全追従している。

## 3. 技術アプローチ
1. **Builder 追加**
   - `YataApp.build` 内の `MaterialApp.router` に `builder` を追加。
   - `Platform.isWindows` 判定で Windows のみ補正ロジックを適用。
2. **縮小率管理**
   - `lib/shared/constants` などに `WindowsScaleSettings` を新設。
   - 既定の縮小率（例: 0.8）と、環境変数／`dart define` で上書きできる仕組みを検討。
3. **MediaQuery 補正**
   - `MediaQuery.of(context)` から元の値を取得し、以下を調整して複製：
     - `devicePixelRatio`: `desiredDpr` (例: 1.0) を設定。
     - `size`: 元サイズを `actualDpr/desiredDpr` でスケーリングし直す。
     - `textScaler`: `media.textScaler.scale(scaleFactor)` を使用し、テキスト倍率を合わせる。
   - 既存値との差分は `scaleFactor = desiredDpr / actualDpr` で計算。
4. **Transform.scale 適用**
   - MediaQuery 差し替え後の子ウィジェットを `Transform.scale(scale: scaleFactor, alignment: Alignment.topLeft)` で包む。
   - `child ?? const SizedBox.shrink()` で null セーフティを確保。
5. **設定切り替え**
   - 将来的なオン/オフ切り替えや数値変更を見越し、`WindowsScaleSettings.enabled` や devtools トグルの余地を残す。

## 4. 追加検討事項
- **ヒットテストずれ**: `Transform.scale` はポインタ位置に影響するため、必要であれば `Transform.scale` を避け、`Matrix4.diagonal3Values` と `Transform` で補正。
- **IME/テキスト入力**: テキストフィールドでキャレット位置が正しく表示されるか確認。
- **スクロールバー**: RawScrollbar の太さや表示位置が変化する可能性。余白補正を検討。
- **アクセシビリティ**: Windows のフォント拡大設定（Ease of Access）を併用した場合の動作確認。

## 5. 実装タスク一覧
1. `WindowsScaleSettings` 作成（const クラス + `fromEnvironment`）
2. `lib/app/app.dart` に builder を追加
3. MediaQuery 差し替えロジック実装（デバイス情報のコピー）
4. Transform 適用とポインタ検証（必要なら `Transform.scale` → `Transform` へ）
5. 主要画面のスポットチェック（Windows 100/125/150%）
6. QA 結果反映（縮小率微調整、トグル追加）
7. ドキュメント更新（README or docs/plan/追記）

## 6. テスト計画
- **手動テスト**
  - Windows 端末で DPI 100% / 125% / 150% を切り替え、主要画面のレイアウト崩れ・スクロール挙動を確認。
  - テキスト入力（注文メモ、検索フィールド）でキャレット位置のズレを確認。
  - ボタンやタイルのクリック領域が期待通りか、ホバー判定に違和感がないかチェック。
- **自動テスト**
  - 既存ウィジェットテストはそのまま動作するはずだが、`MediaQuery` 依存の Golden テストがある場合はスナップショット更新が必要。
  - 新規の自動テストは必須ではないが、`WindowsScaleSettings` のパラメータ計算に対するユニットテストがあると安心。

## 7. リスクと緩和策
| リスク | 緩和策 |
| --- | --- |
| ヒットテストやフォーカスがずれる | `Transform.scale` の使用を最小限にし、`PointerSignalResolver` で挙動確認。必要なら `GestureDetector` の `behavior` 調整。 |
| フォントぼやけ | 縮小率を 0.9〜0.95 など保守的な値に設定。`desiredDpr` を環境設定で調整できるようにする。 |
| アクセシビリティ低下 | Windows のフォントサイズ/スクリーンリーダーでチェックし、必要に応じ `ScaleFactor` を OFF にするトグルを実装。 |
| 将来のレスポンシブ改修と競合 | 別ブランチで管理し、レスポンシブ化開始時に影響範囲を明文化。 |

## 8. スケジュール目安
- 実装・調整: 1.0〜1.2 人日
- QA (DPI パターン + 入力系検証): 0.8 人日
- ドキュメント整備・調整反映: 0.2 人日

**合計目安: 2.0 人日前後 (Most 2.2 人日)**

## 9. 依存・前提条件
- Windows 実行環境（高 DPI モニター含む）での検証が可能であること。
- Flutter バージョンアップ時に `MediaQuery` API の仕様が変わる可能性があるため、変更の影響をウォッチすること。
- 他アプローチ（Win32 側修正、トークン調整）と併用しない前提で作業する。
