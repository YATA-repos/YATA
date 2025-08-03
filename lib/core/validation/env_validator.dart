import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";

import "../logging/yata_logger.dart";

/// 環境変数の検証結果
class EnvValidationResult {
  const EnvValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.info,
  });

  /// 検証が成功したかどうか
  final bool isValid;

  /// エラーメッセージのリスト
  final List<String> errors;

  /// 警告メッセージのリスト
  final List<String> warnings;

  /// 情報メッセージのリスト
  final List<String> info;

  /// エラーがあるかどうか
  bool get hasErrors => errors.isNotEmpty;

  /// 警告があるかどうか
  bool get hasWarnings => warnings.isNotEmpty;

  /// 情報があるかどうか
  bool get hasInfo => info.isNotEmpty;
}

/// 環境変数検証ユーティリティ
/// 
/// アプリケーション起動時に必要な環境変数が正しく設定されているかを検証します。
class EnvValidator {
  EnvValidator._();

  /// 必須の環境変数リスト
  static const List<String> _requiredVars = <String>[
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
  ];

  /// オプションの環境変数リスト
  static const List<String> _optionalVars = <String>[
    "SUPABASE_OAUTH_CALLBACK_URL_DEV",
    "SUPABASE_OAUTH_CALLBACK_URL_PROD",
    "DEBUG_MODE",
    "LOG_LEVEL",
  ];

  /// 環境変数を検証
  static EnvValidationResult validate() {
    YataLogger.info("EnvValidator", "環境変数検証を開始");
    final List<String> errors = <String>[];
    final List<String> warnings = <String>[];
    final List<String> info = <String>[];

    // 必須環境変数のチェック
    for (final String varName in _requiredVars) {
      final String? value = dotenv.env[varName];
      
      if (value == null || value.isEmpty) {
        errors.add("必須環境変数 '$varName' が設定されていません");
        YataLogger.error("EnvValidator", "必須環境変数が未設定: $varName");
      } else {
        // 値の形式チェック
        _validateVarFormat(varName, value, errors, warnings);
        info.add("✓ $varName: 設定済み");
        YataLogger.debug("EnvValidator", "必須環境変数設定確認: $varName");
      }
    }

    // オプション環境変数のチェック
    for (final String varName in _optionalVars) {
      final String? value = dotenv.env[varName];
      
      if (value == null || value.isEmpty) {
        warnings.add("オプション環境変数 '$varName' が設定されていません");
        YataLogger.warning("EnvValidator", "オプション環境変数が未設定: $varName");
      } else {
        _validateVarFormat(varName, value, errors, warnings);
        info.add("✓ $varName: $value");
        YataLogger.debug("EnvValidator", "オプション環境変数設定確認: $varName=$value");
      }
    }

    // 環境別チェック
    _validateEnvironmentSpecific(errors, warnings, info);

    final EnvValidationResult result = EnvValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      info: info,
    );
    
    YataLogger.info("EnvValidator", "環境変数検証完了: 結果=${result.isValid ? '成功' : '失敗'}, エラー数=${errors.length}, 警告数=${warnings.length}");
    return result;
  }

  /// 環境変数の形式を検証
  static void _validateVarFormat(
    String varName,
    String value,
    List<String> errors,
    List<String> warnings,
  ) {
    switch (varName) {
      case "SUPABASE_URL":
        if (!value.startsWith("https://") || !value.contains("supabase.co")) {
          errors.add("SUPABASE_URLの形式が正しくありません: $value");
        }
        break;
        
      case "SUPABASE_ANON_KEY":
        if (!value.startsWith("eyJ")) {
          errors.add("SUPABASE_ANON_KEYの形式が正しくありません（JWTトークンではない）");
        }
        break;
        
      case "SUPABASE_OAUTH_CALLBACK_URL_DEV":
        if (!value.startsWith("http://localhost:")) {
          warnings.add("開発用コールバックURLは通常 http://localhost:8080 です");
        }
        break;
        
      case "SUPABASE_OAUTH_CALLBACK_URL_PROD":
        if (value == "https://yourdomain.com") {
          warnings.add("本番用コールバックURLがデフォルト値のままです");
        } else if (!value.startsWith("https://")) {
          errors.add("本番用コールバックURLはHTTPS必須です: $value");
        }
        break;
        
      case "DEBUG_MODE":
        if (value != "true" && value != "false") {
          warnings.add("DEBUG_MODEは 'true' または 'false' である必要があります: $value");
        }
        break;
        
      case "LOG_LEVEL":
        const List<String> validLevels = <String>["trace", "debug", "info", "warn", "error"];
        if (!validLevels.contains(value.toLowerCase())) {
          warnings.add("LOG_LEVELは ${validLevels.join(', ')} のいずれかである必要があります: $value");
        }
        break;
    }
  }

  /// 環境別の設定を検証
  static void _validateEnvironmentSpecific(
    List<String> errors,
    List<String> warnings,
    List<String> info,
  ) {
    // デバッグモードの確認
    final bool isDebugMode = kDebugMode;
    info.add("🔧 実行環境: ${isDebugMode ? 'デバッグ' : 'リリース'}");

    // プラットフォームの確認
    if (kIsWeb) {
      info.add("🌐 プラットフォーム: Web");
      // Web特有のチェック
      final String? devUrl = dotenv.env["SUPABASE_OAUTH_CALLBACK_URL_DEV"];
      if (devUrl != null && !devUrl.startsWith("http://localhost:")) {
        warnings.add("Web開発環境では localhost のコールバックURLが推奨されます");
      }
    } else {
      final String platform = Platform.operatingSystem;
      info..add("💻 プラットフォーム: $platform")
      ..add("📱 カスタムスキーム: com.example.yata://login (自動設定)");
    }

    // 本番環境の準備状況
    final String? prodUrl = dotenv.env["SUPABASE_OAUTH_CALLBACK_URL_PROD"];
    if (prodUrl == null || prodUrl == "https://yourdomain.com") {
      warnings.add("本番環境の準備が完了していません（コールバックURL未設定）");
    } else {
      info.add("🚀 本番環境準備完了: $prodUrl");
    }
  }

  /// 検証結果をコンソールに出力
  static void printValidationResult(EnvValidationResult result) {
    YataLogger.info("EnvValidator", "========================================");
    YataLogger.info("EnvValidator", "🔍 環境変数検証結果");
    YataLogger.info("EnvValidator", "========================================");

    if (result.hasErrors) {
      YataLogger.error("EnvValidator", "❌ エラー:");
      for (final String error in result.errors) {
        YataLogger.error("EnvValidator", "   $error");
      }
    }

    if (result.hasWarnings) {
      YataLogger.warning("EnvValidator", "⚠️  警告:");
      for (final String warning in result.warnings) {
        YataLogger.warning("EnvValidator", "   $warning");
      }
    }

    if (result.hasInfo) {
      YataLogger.info("EnvValidator", "ℹ️  情報:");
      for (final String info in result.info) {
        YataLogger.info("EnvValidator", "   $info");
      }
    }

    YataLogger.info("EnvValidator", "========================================");
    if (result.isValid) {
      YataLogger.info("EnvValidator", "✅ 環境変数検証: 成功");
    } else {
      YataLogger.error("EnvValidator", "❌ 環境変数検証: 失敗");
    }
    YataLogger.info("EnvValidator", "========================================");
  }

  /// .env.example ファイルと比較して不足している変数をチェック
  static List<String> getMissingVarsFromExample() {
    // 実装は簡略化（実際にはファイルを読み込んで解析）
    final List<String> missing = <String>[];
    
    for (final String varName in _requiredVars) {
      if (dotenv.env[varName] == null) {
        missing.add(varName);
      }
    }
    
    return missing;
  }
}