# YATA プロジェクト - Makefile
# パフォーマンステストと開発タスクの自動化

.PHONY: help performance-test performance-test-quick performance-baseline-update performance-report clean-performance-data test build lint format analyze

# デフォルトターゲット
help:
	@echo "🏗️  YATA プロジェクト - 利用可能なコマンド"
	@echo ""
	@echo "パフォーマンステスト:"
	@echo "  performance-test        完全なパフォーマンス回帰テストを実行"
	@echo "  performance-test-quick  高速パフォーマンステストを実行"
	@echo "  performance-baseline-update  ベースラインを更新"
	@echo "  performance-report      パフォーマンスレポートを生成"
	@echo "  clean-performance-data  パフォーマンスデータをクリーンアップ"
	@echo ""
	@echo "開発タスク:"
	@echo "  test                    全テストを実行"
	@echo "  build                   アプリをビルド"
	@echo "  lint                    コード品質チェック"
	@echo "  format                  コードフォーマット"
	@echo "  analyze                 静的解析"
	@echo ""
	@echo "例: make performance-test"

# =================================================================
# パフォーマンステスト関連
# =================================================================

# 完全なパフォーマンス回帰テスト実行
performance-test:
	@echo "🚀 完全なパフォーマンス回帰テスト実行開始"
	@echo "📊 ベースライン比較とレポート生成を行います"
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs
	dart test/performance/run_performance_tests.dart \
		--regression-threshold=20.0 \
		--no-update-baseline
	@echo ""
	@echo "✅ パフォーマンステスト完了"
	@echo "📈 結果ファイル:"
	@echo "  - performance_test_results.xml (JUnit形式)"
	@echo "  - performance_detailed_report.json (詳細レポート)"
	@echo "  - performance_results.json (実行結果)"

# 高速パフォーマンステスト（基本的なチェックのみ）
performance-test-quick:
	@echo "⚡ 高速パフォーマンステスト実行"
	flutter pub get
	dart test test/performance/benchmarks/provider_performance_test.dart
	@echo "✅ 高速パフォーマンステスト完了"

# ベースライン更新（慎重に実行）
performance-baseline-update:
	@echo "📊 パフォーマンスベースライン更新"
	@echo "⚠️  注意: 現在のパフォーマンスをベースラインとして設定します"
	@read -p "続行しますか？ (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs
	dart test/performance/run_performance_tests.dart \
		--regression-threshold=50.0 \
		--update-baseline
	@echo "✅ ベースライン更新完了"
	@echo "📁 ファイル: performance_baseline.json"

# パフォーマンスレポート生成（テスト実行なし）
performance-report:
	@echo "📊 パフォーマンスレポート生成"
	@if [ -f "performance_detailed_report.json" ]; then \
		echo "🎯 最新のパフォーマンスレポート:"; \
		echo ""; \
		dart -e "import 'dart:convert'; import 'dart:io'; \
		final data = jsonDecode(File('performance_detailed_report.json').readAsStringSync()); \
		print('総テスト数: \$${data['totalTests']}'); \
		print('成功: \$${data['passedTests']}'); \
		print('失敗: \$${data['failedTests']}'); \
		print('回帰検出: \$${data['regressionCount']}'); \
		print('実行時間: \$${data['executionTimeMs']}ms'); \
		print('結果: \$${data['success'] ? '✅ 成功' : '❌ 失敗'}');"; \
	else \
		echo "❌ パフォーマンスレポートが見つかりません"; \
		echo "先に 'make performance-test' を実行してください"; \
	fi

# パフォーマンスデータクリーンアップ
clean-performance-data:
	@echo "🧹 パフォーマンスデータクリーンアップ"
	rm -f performance_baseline.json
	rm -f performance_results.json
	rm -f performance_test_results.xml
	rm -f performance_detailed_report.json
	@echo "✅ クリーンアップ完了"

# =================================================================
# 開発タスク
# =================================================================

# 全テスト実行
test:
	@echo "🧪 全テスト実行"
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs
	flutter test
	@echo "✅ テスト完了"

# アプリビルド
build: format lint
	@echo "🏗️  アプリビルド"
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs
	flutter build apk --debug
	@echo "✅ APKビルド完了: build/app/outputs/flutter-apk/app-debug.apk"

# コード品質チェック
lint:
	@echo "🔍 コード品質チェック"
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs
	flutter analyze
	@echo "✅ 静的解析完了"

# コードフォーマット
format:
	@echo "✨ コードフォーマット"
	dart format lib/ test/ --set-exit-if-changed
	@echo "✅ フォーマット完了"

# 静的解析（詳細）
analyze:
	@echo "🔬 詳細静的解析"
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs
	flutter analyze --fatal-infos
	@echo "✅ 詳細解析完了"

# =================================================================
# 組み合わせタスク
# =================================================================

# CI/CD風の完全チェック
ci-check: format lint test performance-test
	@echo "🎯 CI/CD風完全チェック完了"
	@echo "全ての品質チェックが正常に完了しました"

# 開発前チェック
dev-check: format lint test performance-test-quick
	@echo "👨‍💻 開発前チェック完了"
	@echo "開発を開始できます"

# リリース前チェック
release-check: clean-performance-data performance-baseline-update build test performance-test
	@echo "🚀 リリース前チェック完了"
	@echo "リリースの準備が整いました"

# =================================================================
# ヘルプとバージョン情報
# =================================================================

# 環境情報表示
env-info:
	@echo "🔧 環境情報"
	@echo "Flutter バージョン:"
	@flutter --version
	@echo ""
	@echo "Dart バージョン:"
	@dart --version
	@echo ""
	@echo "プロジェクト情報:"
	@if [ -f "pubspec.yaml" ]; then \
		grep -E "^name:|^version:" pubspec.yaml; \
	fi

# 依存関係情報
deps-info:
	@echo "📦 依存関係情報"
	flutter pub deps --style=tree

# パフォーマンス関連ファイル状況
performance-status:
	@echo "📊 パフォーマンス関連ファイル状況"
	@echo ""
	@if [ -f "performance_baseline.json" ]; then \
		echo "✅ ベースラインファイル: 存在"; \
		stat -c "   更新日時: %y" performance_baseline.json; \
	else \
		echo "❌ ベースラインファイル: 未作成"; \
	fi
	@echo ""
	@if [ -f "performance_detailed_report.json" ]; then \
		echo "✅ 詳細レポート: 存在"; \
		stat -c "   更新日時: %y" performance_detailed_report.json; \
	else \
		echo "❌ 詳細レポート: 未作成"; \
	fi
	@echo ""
	@echo "パフォーマンステストファイル:"
	@find test/performance -name "*.dart" -type f | wc -l | xargs echo "  テストファイル数:"