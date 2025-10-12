# AGENTS.md

このファイルは、LLM/AIエージェントがリポジトリを扱う際の最小限のガイダンスです。

## 原則
- ユーザーとは**日本語**で会話  
- **Serenaを積極活用(projectは"YATA"とする)**  
- **`git rm`やファイル削除は禁止**（ユーザーに提案し、実行は待つ）

## プロジェクト概要
- **名前**: YATA（屋台）  
- **目的**: 小規模飲食店向け在庫・注文管理システム  
- **プラットフォーム**: Flutter（Android/Windows）  
- **機能**: 在庫追跡、注文管理、分析、メニュー管理  

## 技術仕様
- **スタック**: Flutter, Riverpod, Supabase, json_serializable  
- **アーキテクチャ**:  
  `UI → Service → Repository` の直線的依存（Clean Architecture非採用）  
  詳細は `docs/standards/architecture.md`

## 開発ルール
- **Git**:  
  - コミットメッセージは英語、形式例: `feat: add analytics screen`  
  - ブランチ: `feature/`, `fix/`, `chore/`（ベースは`dev`）  
  - PRタイトルも同形式、説明に目的・影響を記載  
- **ドキュメント**:  
  `docs/standards/documentation_guidelines.md` に従い、積極活用