# ロギングドキュメント修正計画

## 概要

現在のロギングドキュメント（`docs/guide/logging/general.md`, `docs/reference/logging-api.md`）をドキュメンテーションガイドラインに準拠するよう修正する計画書。

## 修正対象ファイル

- `docs/guide/logging/general.md` → `docs/guide/logging.md`（移動・リネーム）
- `docs/reference/logging/logging-api.md` → 内容修正

## 修正項目詳細

### 1. ディレクトリ構造・ファイル名の修正

**対象**: `docs/guide/logging/general.md`

**修正内容**:
- ファイル移動: `docs/guide/logging/general.md` → `docs/guide/logging.md`
- サブディレクトリ `logging/` を削除（単一機能のため不要）

**理由**: ドキュメンテーションガイドラインに従い、単一機能の場合はサブディレクトリを使わない

### 2. 相互参照の追加

#### 2.1 guide → reference への参照追加

**対象**: `docs/guide/logging.md`（移動後）

**追加箇所と内容**:

1. **基本的な使い方セクション（行32-50付近）**
   ```markdown
   ### 基本的なログ出力

   各ログレベルの詳細仕様は `reference/logging-api.md` のトップレベル関数を参照してください。

   ```dart
   // レベル別の出力
   t('トレース情報');        // trace
   ...
   ```

2. **ログレベルセクション（行52-74付近）**
   ```markdown
   ## ログレベル

   ログレベルの完全なAPI仕様は `reference/logging-api.md` の LogLevel 列挙型を参照してください。

   ログレベルは以下の6段階があります（重要度順）：
   ...
   ```

3. **タグ機能セクション（行76-103付近）**
   ```markdown
   ### 基本的なタグ使用

   withTag関数の詳細仕様は `reference/logging-api.md` の設定関数セクションを参照してください。

   ```dart
   // 直接指定
   ...
   ```

4. **設定セクション（行171-195付近）**
   ```markdown
   ## 設定

   LogConfigの完全な設定項目は `reference/logging-api.md` の LogConfig クラスを参照してください。

   ### デフォルト設定の使用
   ...
   ```

5. **PII マスキングセクション（行197-231付近）**
   ```markdown
   ## PII（個人情報）マスキング

   PII マスキングの詳細仕様とカスタマイズ方法は `reference/logging-api.md` の PII マスキングセクションを参照してください。

   個人情報は自動的にマスクされます。
   ...
   ```

#### 2.2 reference → guide への参照追加

**対象**: `docs/reference/logging/logging-api.md`

**追加箇所と内容**:

1. **トップレベル関数セクション（行18-95付近）**
   各関数の説明の後に以下を追加:
   ```markdown
   実際の使用例とベストプラクティスは `guide/logging.md` を参照してください。
   ```

2. **Logger クラスセクション（行155-208付近）**
   ```markdown
   ## Logger クラス

   実践的な使用方法は `guide/logging.md` のタグ機能セクションを参照してください。
   
   ### コンストラクタ
   ...
   ```

3. **LogConfig クラスセクション（行278-362付近）**
   ```markdown
   ## LogConfig クラス

   設定のベストプラクティスと実際の使用例は `guide/logging.md` の設定セクションを参照してください。

   ロガーの設定を管理するクラスです。
   ...
   ```

4. **コンテキスト機能セクション（行363-397付近）**
   ```markdown
   ## コンテキスト機能

   コンテキスト機能の実践的な使用方法は `guide/logging.md` のコンテキスト機能セクションを参照してください。

   ### 型定義
   ...
   ```

### 3. 実装ステータスの明示

#### 3.1 reference での🚧マーク追加

**対象**: `docs/reference/logging/logging-api.md`

**修正箇所**:

1. **RateConfig セクション（行478-490付近）**
   ```markdown
   ### RateConfig

   🚧 **実装中（Phase 3予定）** - 2025年Q1実装予定

   レート制限の設定です。
   ...
   ```

2. **CallsiteConfig セクション（行491-501付近）**
   ```markdown
   ### CallsiteConfig

   🚧 **実装中（Phase 3予定）** - 2025年Q1実装予定

   呼び出し元情報の設定です。
   ...
   ```

3. **OverflowPolicy セクション（行465-477付近）**
   ```markdown
   ### OverflowPolicy

   🚧 **実装中（Phase 3予定）** - 2025年Q1実装予定

   キューオーバーフロー時のポリシーです。
   ...
   ```

#### 3.2 guide での開発中機能の明示

**対象**: `docs/guide/logging.md`（移動後）

**修正箇所**:

1. **高度な機能セクション（行273-305付近）**の一時的な設定変更について:
   ```markdown
   ### 一時的な設定変更

   🚧 **開発中機能** - Phase 2で実装予定

   ```dart
   // 一時的に設定を変更
   final result = logger.withTempConfig(() {
   ...
   ```

### 4. 内容構成の責務分離

#### 4.1 guide からの reference的内容の削除

**対象**: `docs/guide/logging.md`（移動後）

**削除対象**:
1. **高度な機能セクション（行273-305付近）**の詳細API説明
   - `logger.stats` の詳細プロパティ説明 → reference に誘導
   - `onStats().listen()` の詳細仕様 → reference に誘導

**修正後**:
```markdown
### 統計情報の取得

統計情報の詳細プロパティは `reference/logging-api.md` の LoggerStats クラスを参照してください。

```dart
// 現在の統計を取得
final stats = logger.stats;
print('キューの長さ: ${stats.queueLength}');
print('ドロップされたログ数: ${stats.droppedSinceStart}');

// 統計の変化を監視
onStats().listen((stats) {
  print('統計更新: $stats');
});
```
```

#### 4.2 reference からの guide的内容の削除

**対象**: `docs/reference/logging/logging-api.md`

**削除対象**:
1. **使用例セクション（行605-660付近）**の詳細チュートリアル
   - 複数の使用パターンの説明 → guide に誘導

**修正後**:
```markdown
## 使用例

基本的な使用方法とベストプラクティスは `guide/logging.md` を参照してください。

### 基本的な使用

```dart
import 'package:yata/infrastructure/logging/logging.dart';

void main() {
  // 基本的なログ出力
  i('アプリケーション開始');
  
  // その他の詳細な使用例は guide/logging.md を参照
}
```
```

### 5. 対象読者への配慮改善

#### 5.1 外部技術の説明追加

**対象**: `docs/guide/logging.md`（移動後）

**追加箇所**:

1. **概要セクション（行19-31付近）**に用語説明を追加:
```markdown
## 概要

このロギングライブラリは以下の機能を提供します：

- **色付きコンソール出力**: 開発時の可読性向上
- **NDJSON ファイル出力**: 本番環境での調査性向上（NDJSON: Newline Delimited JSON - 各行が1つのJSONオブジェクト）
- **PII マスキング**: 個人情報（Personal Identifiable Information）の漏洩リスク最小化
...
```

#### 5.2 中級者向けの詳細説明追加

**対象**: `docs/guide/logging.md`（移動後）

**追加箇所**:

1. **遅延評価セクション（行130-146付近）**に詳細説明を追加:
```markdown
## 遅延評価

パフォーマンスを向上させるため、重い処理は遅延評価を使用します。遅延評価により、ログレベルによってフィルタリングされるログの場合、不要な計算処理をスキップできます。

```dart
// メッセージの遅延評価
d(() => 'Heavy calculation result: ${expensiveCalculation()}');
...

// ログレベルによるフィルタリングで、不要な処理をスキップ
// DEBUGレベルが無効な場合、expensiveCalculation()は実行されない
// これにより本番環境でのパフォーマンス低下を防げます
```
```

### 6. コードブロックの言語指定統一

**対象**: 両ファイル

**修正内容**: すべてのDartコードブロックに `dart` 言語指定を追加

## 修正作業順序

1. `docs/guide/logging/general.md` を `docs/guide/logging.md` に移動
2. `docs/guide/logging.md` の内容修正（相互参照追加、責務分離、対象読者配慮改善）
3. `docs/reference/logging/logging-api.md` の内容修正（相互参照追加、実装ステータス明示、責務分離）
4. 空になった `docs/guide/logging/` ディレクトリの削除
5. 修正後の両ファイルの整合性確認

## 修正後の期待される改善

1. ドキュメンテーションガイドラインへの完全準拠
2. guide と reference の明確な責務分離
3. 相互参照による使いやすさの向上
4. 実装ステータスの明確化
5. 対象読者（Flutter/Dart中級者）への配慮向上

## 注意事項

- 修正作業中は、現在のドキュメントの有用な情報を失わないよう注意
- 相互参照は具体的なセクション名まで含めて正確に記載
- 実装ステータスは plan/ ディレクトリの情報と整合性を保つ