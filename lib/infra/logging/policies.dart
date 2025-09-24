import "dart:convert";
import "dart:io";

/// Rotation policy decides when to roll to a new log file.
abstract class RotationPolicy {
  bool shouldRotate({
    required DateTime now,
    required DateTime openedAt,
    required int currentBytes,
    required int nextRecordBytes,
    required String timezone,
  });
}

class NoRotation implements RotationPolicy {
  const NoRotation();

  @override
  bool shouldRotate({
    required DateTime now,
    required DateTime openedAt,
    required int currentBytes,
    required int nextRecordBytes,
    required String timezone,
  }) => false;
}

class DailyRotation implements RotationPolicy {
  const DailyRotation({this.timezone = "UTC"});

  final String timezone; // 'UTC' or 'local' supported (others treated as UTC)

  @override
  bool shouldRotate({
    required DateTime now,
    required DateTime openedAt,
    required int currentBytes,
    required int nextRecordBytes,
    required String timezone,
  }) {
    final bool useUtc = (this.timezone.toUpperCase() == "UTC");
    final DateTime a = useUtc ? openedAt.toUtc() : openedAt.toLocal();
    final DateTime b = useUtc ? now.toUtc() : now.toLocal();
    return (a.year != b.year) || (a.month != b.month) || (a.day != b.day);
  }
}

class SizeRotation implements RotationPolicy {
  const SizeRotation({required this.maxBytes});
  final int maxBytes;

  @override
  bool shouldRotate({
    required DateTime now,
    required DateTime openedAt,
    required int currentBytes,
    required int nextRecordBytes,
    required String timezone,
  }) {
    // Rotate BEFORE exceeding the threshold
    return (currentBytes + nextRecordBytes) > maxBytes;
  }
}

class CompositeRotation implements RotationPolicy {
  const CompositeRotation(this.policies);
  final List<RotationPolicy> policies;

  @override
  bool shouldRotate({
    required DateTime now,
    required DateTime openedAt,
    required int currentBytes,
    required int nextRecordBytes,
    required String timezone,
  }) {
    for (final RotationPolicy p in policies) {
      if (p.shouldRotate(
        now: now,
        openedAt: openedAt,
        currentBytes: currentBytes,
        nextRecordBytes: nextRecordBytes,
        timezone: timezone,
      )) {
        return true;
      }
    }
    return false;
  }
}

/// Retention policies applied after rotation.
abstract class RetentionPolicy {
  Future<void> apply(Directory dir, String baseName);
}

class NoRetention implements RetentionPolicy {
  const NoRetention();

  @override
  Future<void> apply(Directory dir, String baseName) async {}
}

class MaxFiles implements RetentionPolicy {
  const MaxFiles({this.count = 7});
  final int count;

  @override
  Future<void> apply(Directory dir, String baseName) async {
    final List<FileSystemEntity> all = dir.existsSync() ? dir.listSync() : <FileSystemEntity>[];
    final RegExp re = RegExp("^" + RegExp.escape(baseName) + r"-\d{8}-\d{2}\.log$");
    final List<File> files =
        all.whereType<File>().where((File f) => re.hasMatch(f.uri.pathSegments.last)).toList()
          ..sort((File a, File b) => a.statSync().modified.compareTo(b.statSync().modified));
    if (files.length <= count) return;
    final int toDelete = files.length - count;
    for (int i = 0; i < toDelete; i++) {
      try {
        await files[i].delete();
      } catch (_) {
        // ignore; one-off failures allowed
      }
    }
  }
}

class MaxDays implements RetentionPolicy {
  const MaxDays({this.days = 7});
  final int days;

  @override
  Future<void> apply(Directory dir, String baseName) async {
    if (!dir.existsSync()) return;
    final DateTime cutoff = DateTime.now().toUtc().subtract(Duration(days: days));
    final RegExp re = RegExp("^" + RegExp.escape(baseName) + r"-\d{8}-\d{2}\.log$");
    await for (final FileSystemEntity e in dir.list()) {
      if (e is! File) continue;
      if (!re.hasMatch(e.uri.pathSegments.last)) continue;
      try {
        final FileStat st = await e.stat();
        final DateTime m = st.modified.toUtc();
        if (m.isBefore(cutoff)) {
          await e.delete();
        }
      } catch (_) {
        // ignore
      }
    }
  }
}

class CompositeRetention implements RetentionPolicy {
  const CompositeRetention(this.policies);
  final List<RetentionPolicy> policies;

  @override
  Future<void> apply(Directory dir, String baseName) async {
    for (final RetentionPolicy p in policies) {
      await p.apply(dir, baseName);
    }
  }
}

int utf8BytesLengthWithNewline(String line) {
  // NDJSON line + newline; ensure UTF-8 byte length accounting
  return utf8.encode(line).length + 1;
}
