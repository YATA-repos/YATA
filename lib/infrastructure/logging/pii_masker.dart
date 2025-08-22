import "dart:convert";
import "dart:io";
import "dart:math";
import "dart:typed_data";

import "package:crypto/crypto.dart" as crypto;

import "log_config.dart";
import "log_event.dart";

abstract class Interceptor {
  LogEvent process(LogEvent event);
}

class PiiMasker implements Interceptor {
  PiiMasker({
    required this.enabled,
    required this.mode,
    List<RegExp>? customPatterns,
    List<String>? allowListKeys,
  })  : _customPatterns = customPatterns ?? <RegExp>[],
        _allowListKeys = allowListKeys ?? <String>[] {
    _salt = _randomSalt();
  }

  final bool enabled;
  final MaskMode mode;
  final List<RegExp> _customPatterns;
  final List<String> _allowListKeys;

  late final Uint8List _salt;

  @override
  LogEvent process(LogEvent event) {
    if (!enabled) {
      return event;
    }
    return event.copyWith(
      msg: _maskString(event.msg),
      fields: _maskFields(event.fields),
      ctx: _maskMap(event.ctx),
      err: event.err == null
          ? null
          : <String, String>{
              if (event.err!.containsKey("type")) "type": event.err!["type"]!,
              if (event.err!.containsKey("message")) "message": _maskString(event.err!["message"]!),
            },
      st: event.st == null ? null : _maskString(event.st!),
    );
  }

  Map<String, dynamic>? _maskFields(Map<String, dynamic>? m) {
    if (m == null) {
      return null;
    }
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final MapEntry<String, dynamic> e in m.entries) {
      if (_allowListKeys.contains(e.key)) {
        out[e.key] = e.value;
        continue;
      }
      out[e.key] = _maskValue(e.value, depth: 0);
    }
    return out;
  }

  Map<String, dynamic>? _maskMap(Map<String, dynamic>? m, {int depth = 0}) {
    if (m == null) {
      return null;
    }
    if (depth >= 2) {
      return m; // limit recursion for fields/ctx as spec suggests
    }
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final MapEntry<String, dynamic> e in m.entries) {
      out[e.key] = _maskValue(e.value, depth: depth + 1);
    }
    return out;
  }

  dynamic _maskValue(dynamic v, {required int depth}) {
    if (v is String) {
      return _maskString(v);
    }
    if (v is Map<String, dynamic>) {
      return _maskMap(v, depth: depth);
    }
    if (v is List) {
      return v.map((dynamic x) => _maskValue(x, depth: depth)).toList();
    }
    return v;
  }

  String _maskString(String s) {
    String out = s;

    // 1) IP masking via InternetAddress.tryParse over candidate tokens
    out = _maskIpCandidates(out);

    // 2) Built-in regex patterns
    for (final RegExp r in _builtinPatterns) {
      out = out.replaceAllMapped(r, (Match m) => _maskToken(m.group(0)!));
    }

    // 3) Custom patterns
    for (final RegExp r in _customPatterns) {
      out = out.replaceAllMapped(r, (Match m) => _maskToken(m.group(0)!));
    }

    return out;
  }

  static final List<RegExp> _builtinPatterns = <RegExp>[
    // Email
    RegExp(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"),
    // Phone (loose)
    RegExp(r"\+?\d[\d \-]{8,}\d"),
    // Credit cards (rough, common BINs; not exhaustive)
    RegExp("(?:4[0-9]{12}(?:[0-9]{3})?)" // VISA
        "|(?:5[1-5][0-9]{14})" // MasterCard
        "|(?:3[47][0-9]{13})" // AMEX
        "|(?:6(?:011|5[0-9]{2})[0-9]{12})"), // Discover
    // JWT
    RegExp(r"[A-Za-z0-9\-_]{10,}\.[A-Za-z0-9\-_]{10,}\.[A-Za-z0-9\-_]{10,}"),
    // Tokens (examples)
    RegExp("(sk-[A-Za-z0-9]{16,})|(AKIA[0-9A-Z]{16})"),
    // JP postal code
    RegExp(r"\b\d{3}-\d{4}\b"),
  ];

  String _maskIpCandidates(String s) {
    // Find plausible IP-like tokens (segments of hex/colon/dot) and test each.
    final RegExp candidate = RegExp(r"\b[0-9A-Fa-f:\.]{3,}\b");
    return s.replaceAllMapped(candidate, (Match m) {
      final String g = m.group(0)!;
      final InternetAddress? ip = InternetAddress.tryParse(g);
      if (ip != null) {
        return _maskToken(g);
      }
      return g;
    });
  }

  String _maskToken(String token) => switch (mode) {
      MaskModeRedact() => "[REDACTED]",
      MaskModeHash() => _hashToken(token),
      MaskModePartial(:final int keepTail) => _partialToken(token, keepTail),
    };

  static Uint8List _randomSalt() {
    final Random rng = Random.secure();
    final Uint8List salt = Uint8List(16);
    for (int i = 0; i < salt.length; i++) {
      salt[i] = rng.nextInt(256);
    }
    return salt;
  }

  String _hashToken(String token) {
    final List<int> data = <int>[_salt.length, ..._salt, ...utf8.encode(token)];
    final String h = crypto.sha256.convert(data).toString();
    return "hash:$h";
  }

  String _partialToken(String token, int keepTail) {
    if (token.length <= keepTail) {
      return "*" * token.length;
    }
    final int maskLen = token.length - keepTail;
    return "${"*" * maskLen}${token.substring(token.length - keepTail)}";
  }
}
