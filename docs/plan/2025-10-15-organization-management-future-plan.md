# 組織管理機能の実装計画（将来対応）

**作成日**: 2025-10-15  
**ステータス**: 計画中（暫定実装適用済み）  
**優先度**: 中（本番リリース前に対応必須）

## 背景

現在、CSVエクスポート機能において組織ID（`organization_id`）が必要ですが、認証システムに組織情報が統合されていません。

### 現在の暫定実装

**実装内容**: ユーザーID = 組織ID として動作  
**適用箇所**: `lib/features/export/presentation/controllers/data_export_controller.dart`  
**実装日**: 2025-10-15

```dart
// 暫定的にユーザーIDを組織IDとして使用
if (organizationId == null || organizationId.isEmpty) {
  organizationId = state.user?.id;
  log.w("【暫定実装】組織IDが未設定のため、ユーザーIDを組織IDとして使用");
}
```

### 暫定実装の制限事項

1. **マルチテナント非対応**: 複数組織の管理が不可能
2. **セキュリティリスク**: ユーザーIDが組織識別子として露出
3. **データ整合性**: 組織単位でのデータ分離が不完全
4. **スケーラビリティ**: 将来的な機能拡張が困難

## 目標

適切な組織管理機能を実装し、暫定実装を置き換える。

## 必要な実装

### Phase 1: データベーススキーマ

#### 1.1 organizationsテーブル

```sql
CREATE TABLE public.organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 1.2 user_organizationsテーブル（多対多関係）

```sql
CREATE TABLE public.user_organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member', -- owner, admin, manager, staff, member
  is_primary BOOLEAN DEFAULT false,
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, organization_id)
);

CREATE INDEX idx_user_organizations_user_id ON public.user_organizations(user_id);
CREATE INDEX idx_user_organizations_org_id ON public.user_organizations(organization_id);
```

#### 1.3 locationsテーブル（店舗・拠点管理）

```sql
CREATE TABLE public.locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  is_active BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_locations_org_id ON public.locations(organization_id);
```

### Phase 2: 認証統合

#### 2.1 サインアップ時の組織作成

```dart
Future<void> signUp(String email, String password) async {
  // 1. ユーザー作成
  final user = await supabase.auth.signUp(email: email, password: password);
  
  // 2. デフォルト組織を作成
  final org = await supabase
    .from('organizations')
    .insert({'name': 'My Organization', 'slug': generateSlug()})
    .select()
    .single();
  
  // 3. ユーザーを組織に紐付け
  await supabase.from('user_organizations').insert({
    'user_id': user.id,
    'organization_id': org['id'],
    'role': 'owner',
    'is_primary': true,
  });
  
  // 4. メタデータに組織情報を設定
  await supabase.auth.updateUser({
    'data': {
      'primary_org_id': org['id'],
      'primary_org_name': org['name'],
    }
  });
}
```

#### 2.2 ログイン時の組織情報取得

```dart
Future<void> loadOrganizationContext(String userId) async {
  final result = await supabase
    .from('user_organizations')
    .select('organization_id, role, organizations(id, name, slug)')
    .eq('user_id', userId)
    .eq('is_primary', true)
    .single();
  
  // AuthState の metadata に設定
  return result;
}
```

### Phase 3: アプリケーション層の実装

#### 3.1 OrganizationServiceの作成

```dart
class OrganizationService {
  Future<Organization> getCurrentOrganization(String userId);
  Future<List<Organization>> getUserOrganizations(String userId);
  Future<void> switchOrganization(String userId, String orgId);
  Future<List<Location>> getOrganizationLocations(String orgId);
}
```

#### 3.2 OrganizationProviderの作成

```dart
final currentOrganizationProvider = StateProvider<Organization?>((ref) => null);
final organizationLocationsProvider = FutureProvider<List<Location>>((ref) async {
  final org = ref.watch(currentOrganizationProvider);
  if (org == null) return [];
  return ref.read(organizationServiceProvider).getOrganizationLocations(org.id);
});
```

#### 3.3 DataExportControllerの修正

```dart
_OrganizationContext _resolveOrganizationContext(AuthState state) {
  // 暫定実装を削除し、適切な組織取得ロジックを実装
  final org = ref.read(currentOrganizationProvider);
  final locations = ref.read(organizationLocationsProvider).value ?? [];
  
  return _OrganizationContext(
    organizationId: org?.id,
    requestedBy: state.user?.email ?? state.user?.id,
    locations: locations.map((loc) => ExportLocationOption(
      id: loc.id,
      label: loc.name,
      description: loc.address,
    )).toList(),
  );
}
```

### Phase 4: データマイグレーション

#### 4.1 既存データの移行

```sql
-- 既存のユーザーに対してデフォルト組織を作成
INSERT INTO public.organizations (id, name, slug, created_at)
SELECT 
  gen_random_uuid(),
  'Organization for ' || email,
  'org-' || substring(id::text, 1, 8),
  created_at
FROM auth.users;

-- ユーザーと組織を紐付け
INSERT INTO public.user_organizations (user_id, organization_id, role, is_primary)
SELECT 
  u.id,
  o.id,
  'owner',
  true
FROM auth.users u
JOIN public.organizations o ON o.slug = 'org-' || substring(u.id::text, 1, 8);

-- 既存のordersテーブルのorg_idを更新
UPDATE public.orders
SET org_id = uo.organization_id
FROM auth.users u
JOIN public.user_organizations uo ON uo.user_id = u.id
WHERE orders.user_id = u.id AND orders.org_id IS NULL;
```

### Phase 5: UI/UX の改善

#### 5.1 組織切り替え機能

- ヘッダーに組織選択ドロップダウンを追加
- 複数組織に所属する場合の切り替え機能

#### 5.2 組織設定画面

- 組織名、設定の編集
- メンバー管理
- 店舗/拠点管理

### Phase 6: テストとデプロイ

#### 6.1 テスト項目

- [ ] 新規サインアップ時の組織自動作成
- [ ] ログイン時の組織情報取得
- [ ] CSVエクスポート機能での組織ID使用
- [ ] データマイグレーション検証
- [ ] 複数組織への対応（将来）

#### 6.2 暫定実装の削除

- [ ] `data_export_controller.dart`の暫定実装コードを削除
- [ ] ファイル先頭の警告コメントを削除
- [ ] `_TemporaryImplementationWarningBanner`を削除
- [ ] ログの警告メッセージを削除

## スケジュール

| Phase | 作業内容 | 見積もり | 優先度 |
|-------|---------|---------|--------|
| Phase 1 | データベーススキーマ | 2日 | 高 |
| Phase 2 | 認証統合 | 3日 | 高 |
| Phase 3 | アプリケーション層 | 5日 | 高 |
| Phase 4 | データマイグレーション | 2日 | 中 |
| Phase 5 | UI/UX改善 | 3日 | 中 |
| Phase 6 | テスト・デプロイ | 3日 | 高 |
| **合計** | | **18日** | |

## 関連ファイル

### 暫定実装が含まれるファイル

- `lib/features/export/presentation/controllers/data_export_controller.dart`
- `lib/features/export/presentation/pages/data_export_page.dart`

### 今後作成が必要なファイル

- `lib/features/organization/models/organization_model.dart`
- `lib/features/organization/models/location_model.dart`
- `lib/features/organization/services/organization_service.dart`
- `lib/features/organization/repositories/organization_repository.dart`
- `lib/features/organization/presentation/providers/organization_providers.dart`
- `supabase/migrations/YYYYMMDD_create_organizations.sql`
- `supabase/migrations/YYYYMMDD_create_user_organizations.sql`
- `supabase/migrations/YYYYMMDD_create_locations.sql`

## 参考資料

- [Supabase Auth: User Management](https://supabase.com/docs/guides/auth/managing-user-data)
- [Multi-tenant Architecture with Supabase](https://supabase.com/docs/guides/database/multi-tenancy)
- プロジェクト内の既存実装:
  - `lib/features/auth/models/auth_state.dart`
  - `lib/features/auth/models/user_profile.dart`

## チェックリスト（実装時）

- [ ] データベーススキーマの設計レビュー
- [ ] マイグレーションスクリプトの作成
- [ ] 既存データのバックアップ
- [ ] サービス層の実装
- [ ] リポジトリ層の実装
- [ ] プロバイダーの実装
- [ ] UI/UXの実装
- [ ] ユニットテストの作成
- [ ] 統合テストの作成
- [ ] ドキュメントの更新
- [ ] 暫定実装の削除
- [ ] コードレビュー
- [ ] QA テスト
- [ ] 本番環境へのデプロイ

## 注意事項

⚠️ **重要**: この計画が実装されるまで、CSVエクスポート機能は開発・テスト環境でのみ使用してください。本番環境での使用は推奨されません。
