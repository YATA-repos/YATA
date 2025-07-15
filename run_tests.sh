#!/bin/bash

# YATA プロジェクト - 包括的テスト実行スクリプト
# 全てのテスト種別を順次実行し、レポートを生成

set -e  # エラー時に停止

# カラー出力の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# プロジェクトルートに移動
cd "$(dirname "$0")"

log_info "🚀 YATA テストスイート実行開始"

# テスト結果を格納するディレクトリを作成
REPORTS_DIR="test_reports"
mkdir -p "$REPORTS_DIR"

# 環境準備
log_info "📋 テスト環境の準備中..."

# Flutter依存関係の取得
log_info "📦 Flutter 依存関係を取得中..."
flutter pub get

# テスト用の依存関係確認
log_info "🔍 テスト依存関係を確認中..."
flutter pub deps | grep -E "(flutter_test|mockito|integration_test)" || {
    log_warning "一部のテスト依存関係が見つかりません"
}

# コード生成（必要に応じて）
log_info "🔨 コード生成を実行中..."
flutter packages pub run build_runner build --delete-conflicting-outputs || {
    log_warning "コード生成でエラーが発生しました（継続）"
}

# 1. ユニットテスト実行
log_info "🧪 ユニットテスト実行中..."
UNIT_TEST_OUTPUT="$REPORTS_DIR/unit_tests.txt"

if flutter test test/unit/ > "$UNIT_TEST_OUTPUT" 2>&1; then
    log_success "✅ ユニットテスト完了"
    UNIT_TESTS_PASSED=true
else
    log_error "❌ ユニットテストで失敗がありました"
    UNIT_TESTS_PASSED=false
    cat "$UNIT_TEST_OUTPUT"
fi

# 2. 統合テスト実行（Android Emulator必要）
log_info "🔗 統合テスト実行中..."
INTEGRATION_TEST_OUTPUT="$REPORTS_DIR/integration_tests.txt"

# Android Emulator起動確認
if command -v adb &> /dev/null && adb devices | grep -q "device$"; then
    log_info "📱 Android デバイスを検出、統合テストを実行中..."
    
    if flutter test integration_test/ > "$INTEGRATION_TEST_OUTPUT" 2>&1; then
        log_success "✅ 統合テスト完了"
        INTEGRATION_TESTS_PASSED=true
    else
        log_error "❌ 統合テストで失敗がありました"
        INTEGRATION_TESTS_PASSED=false
        cat "$INTEGRATION_TEST_OUTPUT"
    fi
else
    log_warning "⚠️ デバイスが見つからないため統合テストをスキップ"
    INTEGRATION_TESTS_PASSED=false
fi

# 3. テストカバレッジレポート生成
log_info "📊 テストカバレッジレポート生成中..."
COVERAGE_OUTPUT="$REPORTS_DIR/coverage"

if flutter test --coverage > "$REPORTS_DIR/coverage.txt" 2>&1; then
    log_success "✅ カバレッジレポート生成完了"
    
    # カバレッジHTMLレポート生成（lcov必要）
    if command -v genhtml &> /dev/null; then
        log_info "📈 HTMLカバレッジレポート生成中..."
        genhtml coverage/lcov.info -o "$COVERAGE_OUTPUT" || {
            log_warning "HTMLレポート生成に失敗"
        }
    else
        log_warning "genhtml が見つからないため、HTMLレポートをスキップ"
    fi
    
    COVERAGE_GENERATED=true
else
    log_error "❌ カバレッジレポート生成に失敗"
    COVERAGE_GENERATED=false
fi

# 4. 静的解析実行
log_info "🔍 静的解析実行中..."
ANALYSIS_OUTPUT="$REPORTS_DIR/analysis.txt"

if flutter analyze > "$ANALYSIS_OUTPUT" 2>&1; then
    log_success "✅ 静的解析完了"
    ANALYSIS_PASSED=true
else
    log_error "❌ 静的解析で問題が見つかりました"
    ANALYSIS_PASSED=false
    cat "$ANALYSIS_OUTPUT"
fi

# 5. パフォーマンステスト実行
log_info "⚡ パフォーマンステスト実行中..."
PERFORMANCE_OUTPUT="$REPORTS_DIR/performance.txt"

if flutter test test/test_harness.dart > "$PERFORMANCE_OUTPUT" 2>&1; then
    log_success "✅ パフォーマンステスト完了"
    PERFORMANCE_TESTS_PASSED=true
else
    log_warning "⚠️ パフォーマンステストで問題がありました"
    PERFORMANCE_TESTS_PASSED=false
    cat "$PERFORMANCE_OUTPUT"
fi

# 総合レポート生成
log_info "📋 総合レポート生成中..."
SUMMARY_REPORT="$REPORTS_DIR/test_summary.md"

cat > "$SUMMARY_REPORT" << EOF
# YATA プロジェクト テストレポート

実行日時: $(date '+%Y-%m-%d %H:%M:%S')

## テスト結果サマリー

| テスト種別 | 結果 | 詳細 |
|-----------|------|------|
| ユニットテスト | $([ "$UNIT_TESTS_PASSED" = true ] && echo "✅ PASS" || echo "❌ FAIL") | [詳細](unit_tests.txt) |
| 統合テスト | $([ "$INTEGRATION_TESTS_PASSED" = true ] && echo "✅ PASS" || echo "⚠️ SKIP/FAIL") | [詳細](integration_tests.txt) |
| 静的解析 | $([ "$ANALYSIS_PASSED" = true ] && echo "✅ PASS" || echo "❌ FAIL") | [詳細](analysis.txt) |
| カバレッジ | $([ "$COVERAGE_GENERATED" = true ] && echo "✅ GENERATED" || echo "❌ FAIL") | [詳細](coverage.txt) |
| パフォーマンス | $([ "$PERFORMANCE_TESTS_PASSED" = true ] && echo "✅ PASS" || echo "⚠️ PARTIAL") | [詳細](performance.txt) |

## 推奨アクション

EOF

# 失敗したテストに基づく推奨アクション追加
if [ "$UNIT_TESTS_PASSED" != true ]; then
    echo "- ❗ ユニットテストの失敗を修正してください" >> "$SUMMARY_REPORT"
fi

if [ "$ANALYSIS_PASSED" != true ]; then
    echo "- ❗ 静的解析の警告/エラーを修正してください" >> "$SUMMARY_REPORT"
fi

if [ "$INTEGRATION_TESTS_PASSED" != true ]; then
    echo "- ⚠️ 統合テスト環境の設定を確認してください" >> "$SUMMARY_REPORT"
fi

if [ "$COVERAGE_GENERATED" = true ]; then
    echo "- 📊 カバレッジレポートを確認し、テスト範囲を拡大検討" >> "$SUMMARY_REPORT"
fi

# 最終結果判定
if [ "$UNIT_TESTS_PASSED" = true ] && [ "$ANALYSIS_PASSED" = true ]; then
    log_success "🎉 基本的なテストが全て成功しました！"
    EXIT_CODE=0
else
    log_error "💥 重要なテストで失敗がありました"
    EXIT_CODE=1
fi

log_info "📂 詳細なレポートは $REPORTS_DIR/ ディレクトリを確認してください"
log_info "📋 総合レポート: $SUMMARY_REPORT"

# カバレッジHTMLがある場合は案内
if [ -d "$COVERAGE_OUTPUT" ]; then
    log_info "🌐 HTMLカバレッジレポート: file://$(pwd)/$COVERAGE_OUTPUT/index.html"
fi

log_info "🏁 テストスイート実行完了"
exit $EXIT_CODE
