# YATA

小規模レストラン向けの在庫・注文管理システム

**開発中**: このプロジェクトは現在開発中であり、機能は未完成です。フィードバックやコントリビューションは大歓迎です！

[![GitBook](https://img.shields.io/badge/docs-GitBook-blue)](https://pennes-organization.gitbook.io/yata-docs)
![License](https://img.shields.io/github/license/YATA-repos/YATA)
![Build Status](https://img.shields.io/github/actions/workflow/status/YATA-repos/YATA/flutter.yml?branch=main)

## 概要

YATA（日本語の「屋台」から命名）は、小規模レストラン事業者向けの在庫・注文管理システムです。**フィーチャーベースのサービスレイヤーアーキテクチャ**を採用し、Clean Architectureとは異なり**依存性の逆転を使わず、UI→Service→Repositoryの直線的な依存関係**で構築されています。

## 主要機能(予定)

- **在庫追跡**: 商品・原材料の在庫管理
- **注文管理**: 下書き→アクティブ→完了の状態管理による注文処理
- **分析機能**: 日次summaryとビジネス洞察の自動生成
- **オフラインサポート**: 操作キューと再接続時同期

## プロジェクト固有の設計思想

### アーキテクチャ特徴

**直線的レイヤードアーキテクチャ**（依存性逆転なし）

```text
UI Layer (Flutter Widgets/Pages)
    ↓
Business Services Layer  
    ↓
Repository Layer (Data Access)
```

**重要な基底クラス設計**:

- `BaseModel`: JSONシリアライゼーション機能を持つモデル基底クラス
- `BaseRepository<T>`: 複雑なフィルタリング（AND/OR）を提供するCRUD基底クラス
- **DTO設計思想**: Entityとの変換を前提とせず、高度なdictのように振る舞う

## ドキュメント

- **[docs/guides/](./docs/guides/)**: 開発手順・ベストプラクティス
- **[docs/references/](./docs/references/)**: API仕様・技術詳細

- **[GitBook](https://pennes-organization.gitbook.io/yata-docs/)**: 見やすいオンラインドキュメント
