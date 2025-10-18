# Windows版でのUIスケーリング問題と代替アプローチ案

## 1. 背景と問題点の整理

### 現状の実装

YATA はデスクトップ向け Flutter アプリであり、Linux版では 100% スケーリングが前提の見た目が採用されているのに対して、Windows版では OS の DPI 設定（既定値 125% など）が反映される。その結果、Windows版では UI 全体が拡大される問題が報告された。

この差をなくすため、リポジトリでは `WindowsScaleSettings` クラスと `MediaQuery` の書き換えロジックが追加され、Windows の `devicePixelRatio` を `desiredDevicePixelRatio` に再計算し、その比率で `Transform.scale` で UI 全体を縮小する方法が採用された。

この方法は UI 全体を強制的に縮小することにより Linux版の見た目に近付けるが、クリック判定位置のずれやフォーカスリングの不一致など、プラットフォーム側のレイアウト計算と Flutter の描画結果が一致しない副作用を引き起こす。添付のスクリーンショットでは、黒帯や余白のバランスが崩れているなど、明らかな表示不具合が確認できる。

### OS の DPI スケーリングの仕組み

Windows では「125%」「150%」などのスケーリング設定により 1 論理ピクセルが複数の物理ピクセルで描画される。Flutter for Windows は `FlutterDesktopGetDpiForMonitor` を使用して DPI を取得し、`dpi / 96` の倍率でウィンドウサイズを拡大する。

Linux（例えば Ubuntu）ではデフォルト DPI が 96 であり、多くのディストリビューションではスケーリング設定が無効か 100% に固定されている。そのため Linux版は拡大されない。

125% などの設定が適用される Windows との違いが、UI の拡大縮小の違いとして表面化している。

---

## 2. 考えられる代替アプローチ

ここでは無理やり全体を縮小するのではなく、Windows と Linux で近い見た目を維持しつつ、副作用を抑えるためのアプローチを複数提案する。

### 2.1 DPI非対応モード（OSレベルで拡大させない）

アプリを DPI 非対応として登録することで Windows での自動拡大を無効にし、Linux と同じ 100% 表示にする。Win32 ではアプリケーションマニフェストの `<dpiAware>` 要素や `SetProcessDpiAwareness(PROCESS_SYSTEM_DPI_AWARE)` を使って DPI aware モードを指定できる。これにより OS から提供される `devicePixelRatio` が常に 1.0 となり、追加の縮小処理が不要になる。

**利点**：プラットフォーム側のレイアウト計算と一致するため、クリックずれやフォーカスリングの問題が起こりにくい。  
**注意点**：高 DPI モニターでは UI が小さく感じる可能性があり、ユーザーにとっては読みづらくなるリスクがある。  
→ 高 DPI 環境での可読性を確保するためには、次節の「レスポンシブ設計」と組み合わせ、フォントサイズや余白だけを適度に拡大する必要がある。

### 2.2 レスポンシブ設計を採用する

高 DPI だからと言って単純に全体を縮小するとレイアウト計算の整合性が失われるため、部分的な調整で対応するのが望ましい。Flutter では画面幅・高さや `devicePixelRatio` に応じてウィジェットの大きさや余白を調整するためのフレームワークが提供されている。

- **`responsive_framework` パッケージ**：  
  `ResponsiveWrapper.builder` を利用し、ウィンドウ幅に応じて自動的にスケーリングを行うことができる。Stack Overflow で紹介されている事例では `defaultScale: true` を設定し、モバイル・タブレット・デスクトップなどのブレークポイントごとに `autoScale` や `resize` を指定することでスケーリング問題が解決したと報告されている。

- **`flutter_screenutil` パッケージ**：  
  設計時の画面サイズを指定し、実行時の画面サイズに合わせてウィジェットやフォントサイズを自動的にスケーリングしてくれる。公式の使い方では `.w` や `.h`、`.sp` などの拡張プロパティを使って幅・高さ・フォントをスケーリングする。

**重要なポイント**：全体を一律に縮小するのではなく、フォントサイズや余白・パディングなどを個別に調整すること。これによりプラットフォーム間の見た目を揃えつつ、各ウィジェットのヒットテスト領域やレイアウトが狂わないようにできる。

### 2.3 VisualDensity と TextTheme の調整

Flutter の `VisualDensity` クラスは UI コンポーネントの密度（縦横のコンパクトさ）を調整するための機構であり、`MaterialApp` のテーマに設定することでボタンやリストなどのスペーシングを変更できる。

- OS や入力デバイスによって推奨される密度を切り替えることが推奨されている。  
  例：タッチデバイスでは密度 `0.0`（広め）、マウス主体のデスクトップでは密度 `-1.0`（狭め）。

- Windows版だけフォントが大きく表示される場合は、`ThemeData.textTheme` に `apply(fontSizeFactor: X)` を指定し、`devicePixelRatio` が 1.25 ならフォントサイズを約 0.8 倍にするなど、テキストのみを縮小するアプローチも考えられる。  
  → UI 全体を縮小せずに可読性を保てる。

### 2.4 MediaQuery で DPI を利用してレイアウトを分岐

UI の基準となる画面サイズや余白を `MediaQuery` から取得し、`devicePixelRatio` に応じてレイアウトを分岐させる。

- 例：`devicePixelRatio > 1.1` の場合はボタンやテキストを一回り小さくするロジックを用意し、`devicePixelRatio` が 1.0 付近の Linux では通常のレイアウトを使う。

- Flutter の公式ドキュメントでは、画面幅を基準としたブレークポイント判定や、`LayoutBuilder` を使ったコンテナ内部のサイズ変化への対応方法が解説されている。これを応用して DPI に基づいた調整を行うことができる。

---

## 3. 提案するアプローチのまとめ

| アプローチ | 概要 | 利点 | 注意点 |
|-----------|------|------|--------|
| **DPI非対応モード** | Windows アプリのマニフェストや `SetProcessDpiAwareness` で DPI 拡大を無効化し、OS に 100% 表示させる | プラットフォーム側のレイアウト計算と一致し、クリック位置のずれを防げる | 高 DPI モニターで文字が小さくなるため、別途レイアウト調整が必要 |
| **レスポンシブ設計の導入** | `responsive_framework` や `flutter_screenutil` を用いて画面幅・DPI に応じたスケーリングを行い、フォントや余白だけを調整 | ブレークポイントやデザインサイズを細かく設定でき、Linux と Windows で一貫した見た目を実現しやすい | 個別のサイズ指定が多い場合、移行コストが高く、パッケージの学習が必要 |
| **VisualDensity / TextTheme 調整** | `ThemeData.visualDensity` や `TextTheme.apply` により、ボタン等の密度やフォントサイズをデバイスごとに調整 | 細かい調整が可能で、UI 全体の縮尺を変えずに見た目を揃えられる | 対応するウィジェットに限りがあるため、すべてのレイアウトを網羅できない |
| **MediaQuery による条件分岐** | `devicePixelRatio` や画面幅を取得して、レイアウトやパディングをプログラム的に変える | ライブラリに依存せず柔軟な対応ができる | 条件分岐が増えると可読性が下がり、テスト工数が増える |

---

## 4. 推奨方針

- **短期的には DPI非対応モードの検討**：  
  現状の `Transform.scale` による全体縮小は副作用が大きいため、まず Windows版のアプリケーションマニフェストに `dpiAware` を設定し、OS の自動拡大を抑制する方法を検討する。この時点で Linux と同等の 100% 表示が得られるため、スクリーンショットに見られるレイアウト崩れは解消される可能性が高い。ユーザーが UI を拡大したい場合は次のステップの調整で対応する。

- **中長期的にはレスポンシブ設計へ移行**：  
  高 DPI への対応と将来的なタブレット・Web 展開を見据え、`responsive_framework` や `flutter_screenutil` を導入し、画面幅と DPI に応じてフォントサイズや余白を調整するレスポンシブ設計に移行する。Stack Overflow の回答では `defaultScale: true` とブレークポイントによる自動スケーリングで問題が解決したと報告されている。

- **テーマと密度の調整を併用**：  
  どのアプローチでも、`VisualDensity` や `TextTheme.apply` を利用してデスクトップとモバイルでボタンやフォントの密度を細かく調整することが推奨される。公式ドキュメントでは `visualDensity` による密度調整方法が示されており、これを活用することでプラットフォーム間の見た目の差をさらに縮小できる。

---

## 5. まとめ

Windows版の UI を Linux版に合わせるために UI 全体を縮小する既存の実装は、クリック位置のずれや表示崩れを引き起こす危険を孕んでいる。代替として、

1. OS レベルで DPI 拡大を無効にする  
2. レスポンシブ設計を導入し、フォントや余白のみを柔軟に調整する  
3. `VisualDensity` や `TextTheme` による密度調整を併用する  

といったアプローチが考えられる。これらを段階的に組み合わせることで、Linux の 100% 表示に近い UI 体験を Windows 上でも実現しながら、表示崩れや操作ずれを防止できるだろう。

---

### 参考リンク

- [`windows_scale_settings.dart`](https://raw.githubusercontent.com/YATA-repos/YATA/2583cc35b5f76aae8c3088b72ef6d437e3ff3772/lib/core/constants/windows_scale_settings.dart)  
- [`app.dart`](https://raw.githubusercontent.com/YATA-repos/YATA/2583cc35b5f76aae8c3088b72ef6d437e3ff3772/lib/app/app.dart)  
- [`windows_ui_scaling_analysis.md`](https://github.com/YATA-repos/YATA/blob/2583cc35b5f76aae8c3088b72ef6d437e3ff3772/docs/draft/windows_ui_scaling_analysis.md)  
- [Disable high DPI scaling for flutter on desktop - Stack Overflow](https://stackoverflow.com/questions/71415190/disable-high-dpi-scaling-for-flutter-on-desktop)  
- [Design Your Flutter App For Different Screen Sizes \| Medium](https://medium.com/@rk0936626/design-your-flutter-app-for-different-screen-sizes-9b2bf3b16903)  
- [Building adaptive apps \| Flutter](https://liudonghua123.github.io/flutter_website/ui/layout/building-adaptive-apps/)