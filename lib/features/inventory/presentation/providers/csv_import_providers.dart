import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../services/csv_import_service.dart";

part "csv_import_providers.g.dart";

/// CSVインポートサービスプロバイダー
@riverpod
CSVImportService csvImportService(Ref ref) => CSVImportService(ref: ref);