# Windows UI Scaling Normalization Plan

## 背景
- Windows ビルドで UI 全体が Linux 版と比べて拡大して表示される現象を確認。
- `docs/draft/windows_ui_scaling_analysis.md` より、Windows ランナーが `FlutterDesktopGetDpiForMonitor` の DPI 情報をウィンドウ初期化時に反映する一方、Linux では DPI 未連携で 1.0 スケール固定となっている。
- Flutter アプリ本体では追加スケーリングを施しておらず、プラットフォーム差を埋める補正は未実装。

## 目的
- Windows 環境でも Linux 版と近い論理密度で UI を表示させ、画面設計の一貫性を確保する。
- OS の DPI 意識（Per Monitor V2）の利点を保持しつつ、アプリ側で読みやすさと操作感を調整できる仕組みを導入する。

## 関連ドキュメント
- 調査レポート: `docs/draft/windows_ui_scaling_analysis.md`
- 計測ログテンプレート: `docs/survey/windows_dpi_measurements.md`
- 実装意図メモ: `docs/intent/2025-10-windows-ui-scaling.md`

## 進捗メモ（2025-10-18）
- `lib/main.dart` に `bool.fromEnvironment("LOG_DPI_INFO")` を導入し、`dpi_probe` タグの初期メトリクスログを取得できるようにした。
- Windows 計測用テンプレート (`docs/survey/windows_dpi_measurements.md`) と意図メモ (`docs/intent/2025-10-windows-ui-scaling.md`) を作成し、ログ転記・スクリーンショット管理の手順を明文化した。
- Windows 実機での 100% / 125% / 150% 設定における実測ログ収集とスクリーンショット取得は未実施。担当者アサイン後に着手する。

## 非対象
- ランナー側での DPI スケーリング無効化やマニフェスト変更。
- Windows 以外（macOS など）へのスケーリング補正適用。

## 選定方針
### 採用: アプリ層の密度補正（MediaQuery / Theme 調整）
- 理由: DPI 情報は保持しつつ、Flutter レイヤで論理密度を制御できる。既存設計との乖離を最小化し、他プラットフォームへの拡張も柔軟。

### 非採用
- **ランナーで `scale_factor` を無視**: 高 DPI 環境でのぼやけやゲストアカウントでのサイズ崩れが懸念。
- **OS 設定に委ねるのみ**: ユーザー体験の統一が担保できず、実機レビューでのズレが残存。

## 実装ステップ
1. **現状把握（ログ & スナップショット取得）**
   - `lib/app/main.dart` 起動フローにデバッグ用ログフックを追加し、`devicePixelRatio`・`textScaler`・`physicalSize` を `debugPrint`（または `yataLogger.debug`）で 1 度だけ記録する。コミット前に削除するため `// TODO: remove after DPI normalization` を添付。
   - Windows 端末で `flutter run -d windows --dart-define=LOG_DPI_INFO=true`（予定フラグ）を利用し、実際の DPI 値を取得。結果は `docs/survey/windows_dpi_measurements.md` に記録し、測定日時・OS バージョン・スケール設定・表示結果を明示。
   - 在庫一覧 (`inventory`)、注文画面 (`order`)、ダッシュボード (`dashboard`) の各ページで 100% / 125% / 150% 設定時のスクリーンショットを取得し、`media/ui_scaling/windows_{scale}.png` として保存。Linux 100% の比較キャプチャも取得し、差分を `docs/intent/2025-10-windows-ui-scaling.md` に貼付。
   - ログとキャプチャから、Windows 125% 時に Linux 100% と比べてテキストとコンポーネントが何% 拡大しているかを簡易計測（例: スクリーンショット上でボタン高さを計測）。
2. **補正ファクタ設計**
   - `devicePixelRatio / 1.0` を基準に補正する方法・補正の最大/最小値（例: 0.85～1.0）を決定。極端な DPI（175% 以上）では線形減衰ではなく対数補正を検討し、式を `docs/plan` 内に追記。
   - 設計決定事項（例: `normalizedDensity = clamp(1.0 / devicePixelRatio, 0.75, 1.0)`) を `docs/reference/ui_scaling.md` にまとめ、レビュー依頼を投げる。
   - `shared/foundations/platform_scaling.dart`（新規）に `WindowsScalingResolver` を追加し、Riverpod プロバイダでキャッシュするインターフェースを定義。API 仕様（入力・出力・誤差許容）を Doc コメントで明示。
   - テキストとコンポーネントで別係数を使う場合（`textFactor` と `componentDensityFactor`）の是非を検討し、必要であれば両方定義。
3. **アプリ全体への適用**
   - `MaterialApp.builder` で `MediaQuery` を再構築する `ScalingMediaQuery` ラッパーを導入。Windows 時のみ `textScaler` と `size` を補正値で変換する実装とし、他プラットフォームでは原値を返す条件分岐を実装。
   - `shared/themes/app_theme.dart` に補正値を引数にとる `buildNormalizedTheme(ScalingInfo info)` を追加し、`visualDensity`, `TextTheme`, `ButtonTheme` 等を補正。
   - 既存コンポーネントが直接 `MediaQuery.textScaleFactorOf` を参照している箇所を洗い出し、必要に応じて新しい `ScalingContext` プロバイダ経由に差し替え。該当箇所は `shared/components` と `features/*/presentation` 内で `rg "MediaQuery"` など検索。
   - フラグ制御（例: `bool enableScalingNormalization`）を `app/wiring/provider.dart` で提供し、将来のロールバックや A/B テストが容易な構成にする。
4. **デザインシステム対応**
   - `shared/components` 内で固定ピクセルを使っているウィジェット（`SizedBox(height: XX)` など）を列挙し、`SpacingToken` または `theme.extension<SpacingTheme>()` への置き換え計画を作成。
   - 優先度: 操作頻度が高い UI（在庫テーブル、注文ボタン、フィルター UI）→ 低優先度（設定画面の一部）。各コンポーネントに対し「補正後のターゲット高さ/幅」を定義（例: ボタン高さ 40px 基準）。
   - テキストスタイルの固定 `fontSize` を `AppTypography` トークンに統一し、トークン側で補正係数を掛ける。変更が広範囲になる場合は feature ごとに PR を分割する方針を決定。
5. **検証と調整**
   - Windows 100% / 125% / 150% それぞれで `flutter run -d windows --release` を実行し、補正後の UI 動作を目視確認。スクリーンショットを更新し、Linux 100% と比較して±5% 以内に収まるかを確認。
   - 主要ユースケース（在庫追加、注文入力、設定タブ操作）を手動 QA チェックリスト化し、スケール別に完了判定。
   - `flutter test` を CI ローカルで実行し、ウィジェットテストが補正に追随できているか確認。新たなウィジェットテストが必要な場合はケース（例: `ScalingMediaQuery` の単体テスト）を追加。
   - 補正係数の閾値が利用者の設定幅に対応しきれない場合は、デザイナーと協議し調整値や UI 改修を検討するタスクを別途起票。
6. **ドキュメント整備**
   - 実装完了後に `docs/reference/ui_scaling.md` を正式版に更新し、DPI 補正の仕組み・設定方法・QA 手順を記載。
   - `docs/standards/design_system.md`（存在しない場合は新規）に Windows 向けスケーリング指針を追記し、今後の UI 実装時に参照できるようにする。
   - 変更点のトラブルシュート（ログ取得方法、補正値の確認方法、既知の制限事項）を `docs/guide/troubleshooting.md` に追加。

## 検証計画
- Windows 10/11 のテスト環境で DPI 設定を切り替えて UI の視認性と文字サイズを確認。
- `flutter test` / `dart test` で既存テストに影響がないかを実行。
- 必要に応じてゴールデンテスト導入を検討（今後の課題として記録）。

## リスク・課題
- Windows 特化の調整が他プラットフォームへ漏れ出すと、デザイン差異を再発させる恐れがあるため、スケール補正をプロバイダで厳格に切り替える必要がある。
- 既存 UI でピクセル固定のマジックナンバーが多い場合、追加でリファクタが必要になる。
- ユーザーが 175% 以上の極端な設定を使用するケースでの検証範囲が広がり、要件調整が発生する可能性がある。

## フォローアップ
- macOS ビルド対応や Linux の HiDPI 対策は別タスクとして切り出し、今回の補正ロジックを再利用できるようにしておく。
