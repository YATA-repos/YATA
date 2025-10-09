# Windows版 UIスケーリング調査

## 概要
Windows ビルドでは UI 全体が Linux 版と比べて拡大して表示される現象が確認された。本調査では、プラットフォーム別のランナー実装と Flutter 本体の設定を比較し、差異の要因を整理した。

## 現象の整理
- Linux 版: 1280×720 を基準としたウィンドウサイズで、UI は意図したスケールで表示される。
- Windows 版: 同じ 1280×720 ベースのはずだが、UI コンポーネントが全体的に大きく、Linux 版をそのまま拡大したかのように表示される。

## 調査ポイント
### Windows ネイティブランナーの DPI 処理
- `windows/runner/win32_window.cpp` の `Win32Window::Create` では、`FlutterDesktopGetDpiForMonitor` で取得したモニター DPI を用いて `scale_factor = dpi / 96.0` を計算し、ウィンドウの生成時に `Scale(size.width, scale_factor)` のようにスケールを掛けている。
  - 例: システムの表示スケールが 125% の場合、`dpi ≒ 120` → `scale_factor ≒ 1.25` となり、生成されるウィンドウ幅は 1600px 相当まで拡大する。
- `windows/runner/runner.exe.manifest` では `<dpiAwareness>PerMonitorV2</dpiAwareness>` が設定されており、アプリが高 DPI を前提に描画することを Windows に明示している。
- これらにより、Windows 版は OS レベルの表示スケールを忠実に反映し、Flutter 側の論理ピクセルはそのまま (1280×720 ベース) でも、実際の表示面積は拡大される。

### Linux ランナーとの比較
- `linux/runner/my_application.cc` では `gtk_window_set_default_size(window, 1280, 720);` と固定値をそのまま渡しており、DPI 値に応じたサイズ調整を行っていない。
- 多くの Linux デスクトップ環境では、HiDPI でも GTK への DPI 情報連携が必ずしもデフォルトで行われず、結果として 1.0 倍のスケールで表示されるケースが多い。

### Flutter アプリ本体側の確認
- `lib/main.dart` や `lib/shared/themes/app_theme.dart` を確認したが、`textScaleFactor` や `MediaQuery` の上書き、`DevicePixelRatio` の強制変更などは行っていない。
- テーマ設定も `visualDensity: VisualDensity.standard` で固定しており、プラットフォームごとの追加スケール調整は行っていない。
- そのため、アプリケーションコード自体はプラットフォーム固有の差を意図的に入れていないと判断できる。

## 考察と原因
- Windows 版の UI 拡大は、アプリ側のコードではなく **Windows の DPI Awareness によるスケーリング** が原因と考えられる。
  - Windows ではディスプレイ設定で 125% 以上の拡大率が設定されている場合、Per Monitor V2 対応アプリは DPI 値に合わせて論理ピクセルを物理ピクセルに拡張する。
  - Linux 版ではデフォルトで 100% スケール (DPI ≒ 96) で動作しているため、同じレイアウトでも結果的に Windows の方が大きく見える。
- Flutter は `MediaQuery.of(context).devicePixelRatio` を通じてプラットフォームから渡された DPI をもとにレンダリングを行うため、アプリ側から明示的な補正をしない限り OS 設定に追従する挙動になる。

## 対応に向けた検討事項
- 手元で表示スケールの比較を行う際には、Windows の「ディスプレイの拡大縮小とレイアウト」を 100% に合わせることで Linux 版と近い見た目になる。
- それでも Windows でコンパクトな UI を維持したい場合は、以下のいずれかが必要になる:
  - `windows/runner/win32_window.cpp` 側で取得した `scale_factor` を無視してウィンドウを生成する (ただし高 DPI 環境でのぼやけが発生する恐れあり)。
  - Flutter アプリ内で `MediaQuery` をラップし、Windows の場合に `textScaler` や `VisualDensity` を調整して見た目の密度を高める。
  - OS のディスプレイ設定に合わせたデザイン指標 (レスポンシブレイアウト) を策定し、スケール差を許容する。

以上より、現象は Windows の高 DPI 対応による期待通りの挙動であり、Linux 版との差は OS 側のデフォルト DPI 設定の違いに起因すると結論付けられる。