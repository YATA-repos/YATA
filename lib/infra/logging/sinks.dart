import "dart:async";
import "dart:io";

import "package:path_provider/path_provider.dart";

import "log_config.dart";
import "policies.dart";

abstract class LogSink<T> {
  Future<void> add(T data);
  Future<void> flush();
  Future<void> close();
}

class ConsoleSink implements LogSink<String> {
  ConsoleSink();

  @override
  Future<void> add(String data) async {
    // Always append newline for console readability.
    stdout.writeln(data);
  }

  @override
  Future<void> flush() async {
    await stdout.flush();
  }

  @override
  Future<void> close() async {
    // no-op
  }
}

class FileSink implements LogSink<String> {
  FileSink(this._config)
    : _rotation = _config.rotation,
      _retention = _config.retention,
      _baseName = _config.fileBaseName;

  final LogConfig _config;
  final RotationPolicy _rotation;
  final RetentionPolicy _retention;
  final String _baseName;

  IOSink? _ioSink;
  File? _file;
  Object? lastError;
  bool _failedOnce = false; // one-time warning
  int _linesSinceFlush = 0;
  Timer? _flushTimer;
  Future<void> _serial = Future<void>.value();

  // Rotation state
  DateTime? _openedAtUtc;
  int _currentIndex = 0; // NN part in name
  int _currentBytes = 0; // UTF-8 bytes written so far
  String? _currentYmd; // YYYYMMDD of opened file (UTC by default)
  bool _rotationDisabled = false;

  Future<void> _ensureOpened() async {
    if (_ioSink != null) {
      return;
    }
    try {
      final String dirPath = _config.fileDirPath.isNotEmpty
          ? _config.fileDirPath
          : (await _resolveDefaultDir()).path;
      final Directory dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final DateTime now = DateTime.now().toUtc();
      final RotationPolicy r0 = _rotation;
      final String ymd = _ymd(now, r0 is DailyRotation ? r0.timezone : "UTC");
      _currentIndex = await _nextIndex(dir, _baseName, ymd);
      final String name = _makeFileName(_baseName, ymd, _currentIndex);
      _file = File("${dir.path}/$name");
      _ioSink = _file!.openWrite(mode: FileMode.append);
      _openedAtUtc = now;
      _currentYmd = ymd;
      _currentBytes = await _file!.exists() ? (await _file!.length()) : 0;
    } catch (e) {
      lastError = e;
      if (!_failedOnce) {
        _failedOnce = true;
        stderr.writeln("WARN: FileSink init failed, fallback to console. ($e)");
      }
      rethrow;
    }
  }

  static Future<Directory> _resolveDefaultDir() async {
    try {
      final Directory dir = await getApplicationSupportDirectory();
      return dir;
    } catch (_) {
      // last resort
      return Directory.systemTemp;
    }
  }

  static String _two(int n) => n.toString().padLeft(2, "0");
  static String _ymd(DateTime utcNow, String timezone) {
    final bool useUtc = timezone.toUpperCase() == "UTC";
    final DateTime t = useUtc ? utcNow.toUtc() : utcNow.toLocal();
    final String y = t.year.toString();
    final String m = _two(t.month);
    final String d = _two(t.day);
    return "$y$m$d";
  }

  static String _makeFileName(String base, String ymd, int idx) =>
      "$base-$ymd-${idx.toString().padLeft(2, '0')}.log";

  static Future<int> _nextIndex(Directory dir, String base, String ymd) async {
    int maxIdx = 0;
    final RegExp re = RegExp("^${RegExp.escape(base)}-$ymd-(\\d{2})\\.log\$");
    if (await dir.exists()) {
      await for (final FileSystemEntity e in dir.list()) {
        if (e is! File) {
          continue;
        }
        final String name = e.uri.pathSegments.last;
        final Match? m = re.firstMatch(name);
        if (m != null) {
          final int idx = int.tryParse(m.group(1)!) ?? 0;
          if (idx > maxIdx) {
            maxIdx = idx;
          }
        }
      }
    }
    return maxIdx + 1;
  }

  @override
  Future<void> add(String data) {
    if (_failedOnce) {
      return Future<void>.value();
    }
    return _runSerial(() async {
      try {
        await _ensureOpened();

        final DateTime nowUtc = DateTime.now().toUtc();
        final RotationPolicy rotation = _rotation;
        final String timezone = rotation is DailyRotation ? rotation.timezone : "UTC";
        final int nextBytes = utf8BytesLengthWithNewline(data);
        if (!_rotationDisabled &&
            _openedAtUtc != null &&
            rotation.shouldRotate(
              now: nowUtc,
              openedAt: _openedAtUtc!,
              currentBytes: _currentBytes,
              nextRecordBytes: nextBytes,
              timezone: timezone,
            )) {
          await _rotate(nowUtc);
        }

        _ioSink!.writeln(data);
        _linesSinceFlush++;
        _currentBytes += nextBytes;

        if (_linesSinceFlush >= _config.flushEveryLines) {
          await _performFlushUnsafe();
        } else {
          _scheduleFlushTimerUnsafe();
        }
      } on Object catch (e) {
        lastError = e;
        if (!_failedOnce) {
          _failedOnce = true;
          stderr.writeln("WARN: FileSink write failed, disabling file sink. ($e)");
        }
      }
    });
  }

  Future<void> _rotate(DateTime nowUtc) async {
    try {
      await _performFlushUnsafe();
      await _ioSink?.close();
    } catch (_) {}

    // Open new file with next index or new date
    try {
      final String dirPath = _config.fileDirPath.isNotEmpty
          ? _config.fileDirPath
          : (await _resolveDefaultDir()).path;
      final Directory dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final RotationPolicy r2 = _rotation;
      final String tz = r2 is DailyRotation ? r2.timezone : "UTC";
      final String ymd = _ymd(nowUtc, tz);
      if (_currentYmd != ymd) {
        // new day -> reset index
        _currentIndex = 0;
      }
      _currentIndex = await _nextIndex(dir, _baseName, ymd);
      final String name = _makeFileName(_baseName, ymd, _currentIndex);
      _file = File("${dir.path}/$name");
      _ioSink = _file!.openWrite(mode: FileMode.append);
      _openedAtUtc = nowUtc;
      _currentYmd = ymd;
      _currentBytes = await _file!.exists() ? (await _file!.length()) : 0;

      // Retention after rotation
      try {
        await _retention.apply(dir, _baseName);
      } catch (e) {
        lastError = e;
        // warn once
        if (!_failedOnce) {
          stderr.writeln("WARN: Retention failed ($e)");
        }
      }
    } catch (e) {
      lastError = e;
      // Fallback: disable rotation and continue logging to current file.
      if (!_rotationDisabled) {
        _rotationDisabled = true;
        stderr.writeln("WARN: Rotation failed ($e). Falling back to NoRotation.");
      }
    }
  }

  void _scheduleFlushTimerUnsafe() {
    if (_flushTimer != null) {
      return;
    }
    _flushTimer = Timer(Duration(milliseconds: _config.flushEveryMs), () {
      _flushTimer = null;
      if (_failedOnce) {
        return;
      }
      unawaited(_runSerial(_performFlushUnsafe));
    });
  }

  @override
  Future<void> flush() => _runSerial(_performFlushUnsafe);

  Future<void> _performFlushUnsafe() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_ioSink == null) {
      _linesSinceFlush = 0;
      return;
    }
    try {
      await _ioSink!.flush();
    } on Object catch (e) {
      lastError = e;
      // Maintain previous behavior: keep console fallback without disabling sink.
    } finally {
      _linesSinceFlush = 0;
    }
  }

  @override
  Future<void> close() => _runSerial(() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    try {
      await _performFlushUnsafe();
      await _ioSink?.close();
    } on Object catch (e) {
      lastError = e;
      // ignore
    } finally {
      _ioSink = null;
      _file = null;
    }
  });

  Future<void> _runSerial(FutureOr<void> Function() action) {
    final Future<void> run = _serial.then((_) => Future.sync(action));
    _serial = run.catchError((_) {});
    return run;
  }

  String? get activeFilePath => _file?.path;
}
