import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/utils/provider_logger.dart";
import "../../services/csv_import_service.dart";

part "csv_import_providers.g.dart";

/// CSVインポートサービスプロバイダー
@riverpod
CSVImportService csvImportService(Ref ref) {
  ProviderLogger.info("CSVImportProviders", "CSVImportServiceを初期化しました");
  return CSVImportService(ref: ref);
}