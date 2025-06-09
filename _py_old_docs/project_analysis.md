# rin-stock-manager: Python to Dart Migration Analysis

## プロジェクト概要

**現行システム**: Python 3.12+ / Supabase / Pydantic / Flet (予定)  
**移植先**: Dart / Supabaseクライアント / Flutter (推測)  
**アーキテクチャ**: 階層化モジュール構造（レポジトリ → サービス → UI）  

### 実装状況
- **バックエンド**: 100%完成（repositories, services, models, utils）
- **UI層**: 未実装（Flet予定）
- **テスト**: 未実装
- **オフライン統合**: 30%（FileQueue, ReconnectWatcher実装済み）

## 1. 依存関係分析と移植戦略

### 1.1 Python固有の依存関係

| パッケージ | 用途 | Dart代替案 | 移植難易度 |
|-----------|------|------------|-----------|
| **pydantic** | データ検証・シリアライゼーション | `json_annotation` + `freezed` | 🟡 中 |
| **supabase-py** | Supabaseクライアント | `supabase-flutter` | 🟢 低 |
| **aiofiles** | 非同期ファイルI/O | Dart標準 `dart:io` | 🟢 低 |
| **aiohttp** | 非同期HTTP | Dart標準 `dart:io` / `dio` | 🟢 低 |
| **tenacity** | リトライ機能 | `retry` パッケージ | 🟢 低 |
| **python-decimal** | 高精度演算 | `decimal` パッケージ | 🟡 中 |

### 1.2 非同期パターンの移植

**Python (asyncio) → Dart (Future/Stream)**

```python
# Python
async def create(self, entity: M) -> M | None:
    result = await self.table.insert(serialized_entity).execute()
    return self.model_cls.model_validate(result.data[0]) if result.data else None
```

```dart
// Dart
Future<M?> create(M entity) async {
  final result = await table.insert(serializedEntity);
  return result.isNotEmpty ? ModelClass.fromJson(result.first) : null;
}
```

**移植上の注意点:**
- Pythonの `async`/`await` → Dartの `Future`/`async`/`await`（ほぼ1:1対応）
- Python の `AsyncClient` → Dart の `SupabaseClient`（非同期デフォルト）

## 2. データモデルとシリアライゼーション

### 2.1 Pydanticモデル → Dart クラス変換

**移植難易度: 🟡 中程度**

#### Python (Pydantic)
```python
class Material(CoreBaseModel):
    id: UUID | None = None
    name: str
    category_id: UUID
    current_stock: Decimal
    alert_threshold: Decimal
    
    @classmethod
    def __table_name__(cls) -> str:
        return "materials"
```

#### Dart (freezed + json_annotation)
```dart
@freezed
class Material with _$Material {
  const factory Material({
    String? id,
    required String name,
    required String categoryId,
    required Decimal currentStock,
    required Decimal alertThreshold,
  }) = _Material;
  
  factory Material.fromJson(Map<String, dynamic> json) => _$MaterialFromJson(json);
  
  static String get tableName => 'materials';
}
```

**課題と対策:**
1. **自動検証**: Pydanticの自動検証 → freezedのランタイム検証追加
2. **Decimal型**: python-decimal → Dart `decimal` パッケージ
3. **UUID**: Python uuid → Dart `uuid` パッケージ
4. **Union型**: `UUID | None` → `String?`（nullable型）

### 2.2 シリアライゼーション戦略

**移植難易度: 🟡 中程度**

**Python → Dart 変換パターン:**
- `serialize_for_supabase()` → `toJson()` + カスタムコンバーター
- `Enum.value` → `enum.name` or カスタムシリアライザー
- `Decimal` → `double` または文字列変換

## 3. リポジトリパターンの移植

### 3.1 ジェネリック CRUD リポジトリ

**移植難易度: 🟢 低程度**

#### Python実装
```python
class CrudRepository(ABC, Generic[M, ID]):
    def __init__(self, client: SupabaseClient, model_cls: type[M]):
        self._client = client.supabase_client
        self.model_cls = model_cls
```

#### Dart移植版
```dart
abstract class CrudRepository<M, ID> {
  final SupabaseClient _client;
  final M Function(Map<String, dynamic>) _fromJson;
  final String _tableName;
  
  CrudRepository(this._client, this._fromJson, this._tableName);
  
  Future<M?> create(M entity) async {
    final json = entity.toJson();
    final result = await _client.from(_tableName).insert(json).select().single();
    return _fromJson(result);
  }
}
```

**移植時の考慮点:**
1. **型安全性**: Dartの強い型システムを活用
2. **コンストラクタ**: ファクトリー関数の明示的な渡し
3. **エラーハンドリング**: SupabaseExceptionの適切な処理

### 3.2 フィルタリングシステム

**移植難易度: 🔴 高程度**

#### Python実装（複雑な論理条件サポート）
```python
class OrCondition(LogicalCondition):
    def __init__(self, conditions: list[SimpleFilter]):
        self.conditions = conditions
    
    def to_supabase_filter(self) -> dict[str, Any]:
        return {"type": "or", "conditions": self.conditions}
```

#### Dart移植案
```dart
abstract class FilterCondition {
  Map<String, dynamic> toSupabaseFilter();
}

class OrCondition implements FilterCondition {
  final List<Map<String, dynamic>> conditions;
  OrCondition(this.conditions);
  
  @override
  Map<String, dynamic> toSupabaseFilter() {
    return {'type': 'or', 'conditions': conditions};
  }
}
```

**課題:**
- Pythonの動的型システム → Dartの静的型システム
- 複雑なクエリビルダーの型安全な実装
- FilterOpの列挙型変換

## 4. サービス層の移植

### 4.1 ビジネスロジックサービス

**移植難易度: 🟢 低程度**

#### 主要パターン
1. **依存性注入**: コンストラクタベースの注入（Dartでもそのまま適用可能）
2. **async/await**: Dartでも同様に使用可能
3. **エラーハンドリング**: try-catch → Dartのtry-catch

#### 注意点
```python
# Python: デフォルト引数とNone処理
async def find(self, filters: Filter | None = None) -> list[M]:
    if filters:
        query = apply_filters_to_query(query, filters)
```

```dart
// Dart: nullable型の明示的チェック
Future<List<M>> find({Filter? filters}) async {
  if (filters != null) {
    query = applyFiltersToQuery(query, filters);
  }
}
```

### 4.2 計算ロジックの移植

**移植難易度: 🟡 中程度**

#### Python (Decimal精度)
```python
def calculate_material_usage_rate(self, material_id: UUID, days: int) -> float | None:
    total_consumption = sum(abs(float(t.change_amount)) for t in transactions)
    return total_consumption / days if days > 0 else None
```

#### Dart (精度対応)
```dart
double? calculateMaterialUsageRate(String materialId, int days) {
  final totalConsumption = transactions
      .map((t) => t.changeAmount.abs())
      .fold(0.0, (sum, amount) => sum + amount.toDouble());
  return days > 0 ? totalConsumption / days : null;
}
```

**課題:** 
- Decimal精度の保持
- 通貨計算の精度要件

## 5. オフライン機能の移植

### 5.1 FileQueue実装

**移植難易度: 🟡 中程度**

#### Python実装
```python
class FileQueue:
    async def push(self, record: dict) -> None:
        async with self._lock:
            async with aiofiles.open(self.queue_file, "a") as f:
                await f.write(json.dumps(record) + "\n")
```

#### Dart移植版
```dart
class FileQueue {
  final File _queueFile;
  final _lock = Lock();
  
  Future<void> push(Map<String, dynamic> record) async {
    await _lock.synchronized(() async {
      await _queueFile.writeAsString(
        '${jsonEncode(record)}\n',
        mode: FileMode.append,
      );
    });
  }
}
```

**移植課題:**
- `aiofiles` → Dart `dart:io`
- `asyncio.Lock` → `synchronized` パッケージ
- JSONエンコーディングの一貫性

### 5.2 ReconnectWatcher実装

**移植難易度: 🟢 低程度**

#### 移植方針
- `aiohttp` → `dart:io` HttpClient または `dio`
- `asyncio.create_task` → Dart `Timer.periodic` または `Stream`
- バックオフ戦略はそのまま移植可能

## 6. 設定管理とシークレット

### 6.1 環境設定

**移植難易度: 🟢 低程度**

#### Python (pydantic-settings)
```python
class Settings(BaseSettings):
    SUPABASE_URL: str
    SUPABASE_ANON_KEY: str
    
    class Config:
        env_file = ".env"
```

#### Dart移植版
```dart
class Settings {
  static String get supabaseUrl => 
      dotenv.env['SUPABASE_URL'] ?? _throw('SUPABASE_URL not found');
  static String get supabaseAnonKey => 
      dotenv.env['SUPABASE_ANON_KEY'] ?? _throw('SUPABASE_ANON_KEY not found');
}
```

## 7. 移植戦略とロードマップ

### 7.1 段階的移植アプローチ

#### Phase 1: コアインフラ（2-3週間）
1. **プロジェクト構築**
   - Flutterプロジェクト作成
   - パッケージ依存関係設定
   - ディレクトリ構造構築

2. **基盤クラス移植**
   - `CoreBaseModel` → Dartの基底クラス
   - 型定義（UUID, Decimal, Enum）
   - シリアライゼーション機能

3. **Supabaseクライアント**
   - 接続設定
   - 認証フロー

#### Phase 2: データ層（3-4週間）
1. **モデルクラス移植**
   - 全ドメインモデル（Material, Order, etc.）
   - DTOクラス
   - バリデーション機能

2. **リポジトリ移植**
   - CrudRepository基底クラス
   - ドメイン固有リポジトリ
   - フィルタリングシステム

#### Phase 3: ビジネスロジック（4-5週間）
1. **サービス層移植**
   - InventoryService
   - OrderService
   - AnalyticsService
   - MenuService

2. **計算ロジック**
   - 在庫計算
   - 分析機能
   - レポート生成

#### Phase 4: オフライン機能（2-3週間）
1. **FileQueue移植**
2. **ReconnectWatcher移植**
3. **統合テスト**

#### Phase 5: UI開発（6-8週間）
1. **Flutter UI実装**
2. **状態管理**
3. **ナビゲーション**

### 7.2 リスク評価

| リスク項目 | レベル | 対策 |
|-----------|--------|------|
| **Decimal精度問題** | 🔴 高 | 計算ライブラリの検証、テストケース充実 |
| **型安全性の差** | 🟡 中 | 厳密な型定義、コンパイルエラー対応 |
| **パフォーマンス差** | 🟡 中 | ベンチマーク測定、最適化実装 |
| **非同期パターン** | 🟢 低 | Dart/Flutterの非同期ベストプラクティス適用 |

### 7.3 成功要因

1. **段階的移植**: 機能単位での段階的な移植
2. **テスト駆動**: 移植時の同時テスト作成
3. **機能パリティ**: Python版との機能一致を保証
4. **パフォーマンス検証**: 計算精度とパフォーマンスの詳細検証

## 8. 推奨移植順序

1. **設定・型定義** → **モデル** → **リポジトリ** → **サービス** → **オフライン機能** → **UI**
2. **各段階でのテスト実装を必須とする**
3. **Pythonバージョンとの並行開発・検証**

この分析に基づき、段階的かつ確実な移植を実行することで、元のPythonシステムの機能とパフォーマンスを維持しつつ、Dart/Flutterの利点を活かしたアプリケーションを構築できます。