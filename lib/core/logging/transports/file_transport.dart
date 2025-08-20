import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

class _WriteMsg {
  _WriteMsg(this.levelSeverity, this.line, {this.flush = false});
  final int levelSeverity; // for immediate flush threshold check in isolate if needed
  final String line;
  final bool flush;
}

class _FlushMsg {}
class _DisposeMsg {}
class _RotateNow {}
class _AckMsg {
  _AckMsg(this.ok);
  final bool ok;
}
class _StatsReq {}
class _StatsRes {
  _StatsRes(this.diskUsageMB);
  final int diskUsageMB;
}

class FileTransport {
  FileTransport({
    required this.dir,
    required this.maxFileSizeBytes,
    required this.maxDiskMB,
    required this.retentionDays,
    required this.flushInterval,
  });

  final Directory dir;
  final int maxFileSizeBytes;
  final int maxDiskMB;
  final int retentionDays;
  final Duration flushInterval;

  late SendPort _sp;
  late ReceivePort _rp;
  Isolate? _iso;

  Future<void> start() async {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _rp = ReceivePort();
    _iso = await Isolate.spawn(_fileWriterMain, {
      'send': _rp.sendPort,
      'dir': dir.path,
      'maxFileSizeBytes': maxFileSizeBytes,
      'maxDiskMB': maxDiskMB,
      'retentionDays': retentionDays,
      'flushIntervalMs': flushInterval.inMilliseconds,
    });
    final c = Completer<void>();
    _rp.listen((msg) {
      if (msg is SendPort) {
        _sp = msg;
        c.complete();
      }
    });
    await c.future;
  }

  Future<bool> writeLine(String line, {required int levelSeverity, bool flush = false}) async {
    final rp = ReceivePort();
    _sp.send([rp.sendPort, _WriteMsg(levelSeverity, line, flush: flush)]);
    final res = await rp.first;
    if (res is _AckMsg) return res.ok;
    return false;
  }

  Future<void> flush() async {
    final rp = ReceivePort();
    _sp.send([rp.sendPort, _FlushMsg()]);
    await rp.first;
  }

  Future<int> diskUsageMB() async {
    final rp = ReceivePort();
    _sp.send([rp.sendPort, _StatsReq()]);
    final res = await rp.first;
    if (res is _StatsRes) return res.diskUsageMB;
    return 0;
  }

  Future<void> dispose() async {
    final rp = ReceivePort();
    _sp.send([rp.sendPort, _DisposeMsg()]);
    await rp.first;
    _rp.close();
    _iso?.kill(priority: Isolate.immediate);
  }
}

void _fileWriterMain(Map args) async {
  final parent = args['send'] as SendPort;
  final dir = Directory(args['dir'] as String);
  final maxFileSizeBytes = args['maxFileSizeBytes'] as int;
  final maxDiskMB = args['maxDiskMB'] as int;
  final retentionDays = args['retentionDays'] as int;
  final flushInterval = Duration(milliseconds: args['flushIntervalMs'] as int);

  final rp = ReceivePort();
  parent.send(rp.sendPort);

  IOSink? sink;
  File? current;
  int currentSize = 0;

  String newFileName() {
    final ts = DateTime.now();
    final pid = pidFileSafe();
    final stamp =
        '${ts.year.toString().padLeft(4, '0')}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}-${ts.hour.toString().padLeft(2, '0')}${ts.minute.toString().padLeft(2, '0')}${ts.second.toString().padLeft(2, '0')}';
    return 'YATA-$stamp-$pid-0.jsonl';
  }

  String pidFileSafe() {
    try {
      return (pid).toString();
    } catch (_) {
      return '0';
    }
  }

  Future<void> rotateIfNeeded({bool force = false}) async {
    if (force || sink == null || currentSize >= maxFileSizeBytes) {
      await sink?.flush();
      await sink?.close();
      final name = newFileName();
      current = File('${dir.path}${Platform.pathSeparator}$name');
      sink = current!.openWrite(mode: FileMode.append);
      currentSize = await current!.exists() ? await current!.length() : 0;
      await _cleanup(dir, maxDiskMB, retentionDays);
    }
  }

  Timer.periodic(flushInterval, (t) async {
    try {
      await sink?.flush();
    } catch (_) {}
    await _cleanup(dir, maxDiskMB, retentionDays);
  });

  await rotateIfNeeded(force: true);

  rp.listen((req) async {
    final SendPort reply = (req as List).first as SendPort;
    final Object cmd = req[1] as Object;
    if (cmd is _WriteMsg) {
      try {
        await rotateIfNeeded();
        final bytes = utf8.encode(cmd.line);
        sink!.add(bytes);
        currentSize += bytes.length;
        if (cmd.flush) {
          await sink!.flush();
        }
        reply.send(_AckMsg(true));
      } catch (_) {
        reply.send(_AckMsg(false));
      }
      if (currentSize >= maxFileSizeBytes) {
        await rotateIfNeeded(force: true);
      }
    } else if (cmd is _FlushMsg) {
      try {
        await sink?.flush();
      } catch (_) {}
      reply.send(_AckMsg(true));
    } else if (cmd is _StatsReq) {
      final mb = await _dirSizeMB(dir);
      reply.send(_StatsRes(mb));
    } else if (cmd is _DisposeMsg) {
      try {
        await sink?.flush();
        await sink?.close();
      } catch (_) {}
      reply.send(_AckMsg(true));
    }
  });
}

Future<int> _dirSizeMB(Directory dir) async {
  int total = 0;
  if (!dir.existsSync()) return 0;
  await for (final e in dir.list(recursive: false, followLinks: false)) {
    if (e is File && e.path.endsWith('.jsonl')) {
      total += await e.length();
    }
  }
  return (total / (1024 * 1024)).floor();
}

Future<void> _cleanup(Directory dir, int maxDiskMB, int retentionDays) async {
  if (!dir.existsSync()) return;
  final files = (await dir
          .list(recursive: false, followLinks: false)
          .where((e) => e is File && e.path.endsWith('.jsonl'))
          .cast<File>()
          .toList())
      ..sort((a, b) => a.statSync().changed.compareTo(b.statSync().changed));

  final now = DateTime.now();
  // retention by age
  for (final f in files) {
    final st = f.statSync();
    if (now.difference(st.changed).inDays > retentionDays) {
      try { await f.delete(); } catch (_) {}
    }
  }
  // enforce total disk quota
  int total = 0;
  final survivors = <File>[];
  for (final f in (await dir
          .list(recursive: false, followLinks: false)
          .where((e) => e is File && e.path.endsWith('.jsonl'))
          .cast<File>()
          .toList())
    ..sort((a, b) => a.statSync().changed.compareTo(b.statSync().changed))) {
    final len = await f.length();
    total += len;
    survivors.add(f);
  }
  final limit = maxDiskMB * 1024 * 1024;
  for (final f in survivors) {
    if (total <= limit) break;
    final len = await f.length();
    try { await f.delete(); } catch (_) {}
    total -= len;
  }
}