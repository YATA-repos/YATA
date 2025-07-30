# 🚀 本番環境セットアップガイド

このガイドでは、YATAアプリケーションを本番環境で動作させるための設定手順を説明します。

## 📋 前提条件

- [x] Supabaseプロジェクト作成済み
- [x] Google OAuth設定完了済み
- [x] 開発環境でのテスト完了

## 🔧 本番環境設定

### 1. 環境変数設定

`.env`ファイルを本番環境用に更新します：

```bash
# 本番用 .env ファイル
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_anon_public_key_here

# 本番用コールバックURL
SUPABASE_OAUTH_CALLBACK_URL_DEV=http://localhost:8080
SUPABASE_OAUTH_CALLBACK_URL_PROD=https://your-production-domain.com

# 本番環境設定
DEBUG_MODE=false
LOG_LEVEL=warn
```

### 2. Supabase本番設定

#### Authentication → URL Configuration

1. **Site URL**
   ```
   https://your-production-domain.com
   ```

2. **Redirect URLs**
   ```
   http://localhost:8080                    # 開発環境用
   https://your-production-domain.com       # Web本番用
   com.example.yata://login                 # Desktop/Mobile用
   ```

#### Row Level Security (RLS)

データベースのセキュリティ設定を確認：

1. **すべてのテーブルでRLSを有効化**
   ```sql
   ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
   ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
   ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
   -- 他のすべてのテーブルも同様
   ```

2. **ユーザー別アクセス制御ポリシー**
   ```sql
   -- 例: ordersテーブルのポリシー
   CREATE POLICY "Users can only access their own orders" ON orders
   FOR ALL USING (auth.uid() = user_id);
   ```

### 3. Firebase/Google OAuth設定

#### Authorized Origins
```
https://your-production-domain.com
```

#### Authorized Redirect URIs
```
https://your-production-domain.com
https://your-project-id.supabase.co/auth/v1/callback
```

### 4. ビルド設定

#### Web用ビルド
```bash
flutter build web --release
```

#### Desktop用ビルド
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

#### Mobile用ビルド
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 🔒 セキュリティ設定

### 1. 環境変数の管理

本番環境では以下に注意：

- [x] `.env`ファイルをGitで管理しない（`.gitignore`に追加済み）
- [x] 本番サーバーで環境変数を設定
- [x] CI/CDパイプラインでのシークレット管理

### 2. CORS設定

Supabaseでのクロスオリジン設定：

```
Authentication → Settings → CORS
- 本番ドメインを追加
- 不要なドメインを削除
```

### 3. API制限

Supabaseでの制限設定：

```
Settings → API → API Settings
- Rate limiting有効化
- 不正アクセス防止
```

## 📊 監視・ログ設定

### 1. エラー監視

本番環境でのエラー監視設定：

```dart
// main.dart での設定例
if (kReleaseMode) {
  // 本番環境用エラー監視
  FlutterError.onError = (details) {
    // エラー収集サービスに送信
  };
}
```

### 2. ログレベル設定

```bash
# 本番環境 .env
LOG_LEVEL=warn
DEBUG_MODE=false
```

### 3. パフォーマンス監視

Supabaseでのクエリ監視：

```
Dashboard → SQL Editor → Query insights
```

## 🧪 本番前テスト

### 1. 認証フローテスト

- [ ] ログイン機能
- [ ] ログアウト機能
- [ ] セッション管理
- [ ] 自動セッション更新

### 2. データアクセステスト

- [ ] マルチテナント分離
- [ ] RLSポリシー動作
- [ ] データ整合性

### 3. プラットフォーム別テスト

- [ ] Web ブラウザ
- [ ] Desktop アプリ
- [ ] Mobile アプリ

## 🚀 デプロイ手順

### Web (Firebase Hosting / Netlify / Vercel)

1. ビルド実行
   ```bash
   flutter build web --release --web-renderer canvaskit
   ```

2. 本番環境変数設定
3. デプロイ実行

### Desktop (GitHub Releases / Microsoft Store)

1. ビルド実行
   ```bash
   flutter build windows --release
   ```

2. インストーラー作成
3. 配布

### Mobile (App Store / Google Play)

1. ビルド実行
   ```bash
   flutter build appbundle --release
   ```

2. ストア申請

## 🔄 メンテナンス

### 1. 定期メンテナンス

- [ ] Supabaseプロジェクト監視
- [ ] データベースバックアップ
- [ ] 使用量監視

### 2. アップデート

- [ ] Flutter SDK更新
- [ ] 依存関係更新
- [ ] セキュリティ更新

## 📞 トラブルシューティング

### よくある問題

1. **認証エラー**
   - コールバックURL設定確認
   - CORS設定確認

2. **データアクセスエラー**
   - RLSポリシー確認
   - 環境変数確認

3. **パフォーマンス問題**
   - クエリ最適化
   - インデックス設定

### 支援リソース

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Deployment](https://docs.flutter.dev/deployment)
- プロジェクト内 `docs/` フォルダ

---

## 📝 チェックリスト

本番デプロイ前の最終確認：

- [ ] 環境変数設定完了
- [ ] Supabase設定完了
- [ ] セキュリティ設定完了
- [ ] 監視設定完了
- [ ] テスト完了
- [ ] バックアップ設定完了
- [ ] ドキュメント更新完了

**✅ すべてのチェックが完了したら本番デプロイ可能です！**