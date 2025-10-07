import "dart:math";
import "dart:typed_data";

import "package:archive/archive.dart";

import "../../../core/contracts/export/export_contracts.dart";

class CsvExportEncryptionResult {
  const CsvExportEncryptionResult({
    required this.bytes,
    required this.fileName,
    required this.contentType,
    required this.info,
  });

  final List<int> bytes;
  final String fileName;
  final String contentType;
  final CsvExportEncryptionInfo info;
}

class CsvExportEncryptionService {
  CsvExportEncryptionService({
    Random? random,
    int? passwordLength,
    String? passwordAlphabet,
  })  : _random = random ?? Random.secure(),
        _passwordLength = passwordLength ?? _defaultPasswordLength,
        _alphabet = passwordAlphabet ?? _defaultPasswordAlphabet;

  static const int _defaultPasswordLength = 16;
  static const String _defaultPasswordAlphabet =
      "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#%*+-";

  final Random _random;
  final int _passwordLength;
  final String _alphabet;

  Future<CsvExportEncryptionResult?> maybeEncrypt({
    required String fileName,
    required List<int> csvBytes,
    required Map<String, dynamic>? metadata,
  }) async {
    final bool requiredFlag = _isEncryptionRequired(metadata);
    if (!requiredFlag) {
      return null;
    }

    final List<Map<String, dynamic>> reasons = _extractReasons(metadata);
    final String password = _generatePassword();
    final String archiveFileName = _buildEncryptedFileName(fileName);

    final Archive archive = Archive()
      ..addFile(ArchiveFile(fileName, csvBytes.length, csvBytes));

    final ZipEncoder encoder = ZipEncoder(password: password);
    final List<int>? compressed =
        encoder.encode(archive, level: DeflateLevel.bestSpeed);
    if (compressed == null) {
      throw StateError("Failed to encode encrypted ZIP for $fileName");
    }

    final CsvExportEncryptionInfo info = CsvExportEncryptionInfo(
      required: true,
      password: password,
      originalFileName: fileName,
      reasons: reasons,
    );

    return CsvExportEncryptionResult(
      bytes: Uint8List.fromList(compressed),
      fileName: archiveFileName,
      contentType: "application/zip",
      info: info,
    );
  }

  bool _isEncryptionRequired(Map<String, dynamic>? metadata) {
    if (metadata == null) {
      return false;
    }
    final Object? flag = metadata["encryption_required"];
    if (flag is bool) {
      return flag;
    }
    final Object? nested = metadata["pii_scan"];
    if (nested is Map<String, dynamic>) {
      final Object? nestedFlag = nested["encryption_required"];
      if (nestedFlag is bool) {
        return nestedFlag;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> _extractReasons(Map<String, dynamic>? metadata) {
    if (metadata == null) {
      return const <Map<String, dynamic>>[];
    }

    final Object? rawReasons = metadata["encryption_reasons"] ??
        (metadata["pii_scan"] is Map<String, dynamic>
            ? (metadata["pii_scan"] as Map<String, dynamic>)["detected_rules"]
            : null);

    if (rawReasons is List) {
      return rawReasons
          .whereType<Map<dynamic, dynamic>>()
          .map<Map<String, dynamic>>(
            (Map<dynamic, dynamic> value) => value.map(
              (dynamic key, dynamic val) => MapEntry(key.toString(), val),
            ),
          )
          .toList();
    }

    return const <Map<String, dynamic>>[];
  }

  String _generatePassword() {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < _passwordLength; i++) {
      final int index = _random.nextInt(_alphabet.length);
      buffer.write(_alphabet[index]);
    }
    return buffer.toString();
  }

  String _buildEncryptedFileName(String original) {
    const String suffix = ".csv";
    if (original.toLowerCase().endsWith(suffix)) {
      return original.substring(0, original.length - suffix.length) + ".csv.enc.zip";
    }
    return "$original.enc.zip";
  }
}
