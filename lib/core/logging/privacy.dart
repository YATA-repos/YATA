import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

typedef RedactionRule = String Function(String key, String value);

class Redactor {
  Redactor({List<String>? allowFields})
      : _allow = {...?allowFields};

  final Set<String> _allow;

  static final RegExp _email = RegExp(
      r'(?i)[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
  static final RegExp _token =
      RegExp(r'(?i)(bearer\s+)?[A-Za-z0-9\-\._]{16,}');

  bool _isSensitiveKey(String key) {
    final k = key.toLowerCase();
    if (_allow.contains(key)) return false;
    return k.contains('token') ||
        k.contains('authorization') ||
        k.contains('password') ||
        k == 'pass' ||
        k == 'pwd' ||
        k.contains('email') ||
        k == 'userid';
  }

  Object? redactValue(String key, Object? value) {
    if (!_isSensitiveKey(key)) return value;
    final s = value?.toString() ?? '';
    // email
    String out = s.replaceAllMapped(_email, (m) => '***@***');
    // token-like
    out = out.replaceAllMapped(_token, (m) {
      final v = m.group(0)!;
      if (v.length <= 6) return '*' * v.length;
      return v.substring(0, 4) + ('*' * (v.length - 6)) + v.substring(v.length - 2);
    });
    // password-like (fallback)
    if (out == s) {
      out = '*' * s.length;
    }
    return out;
  }
}

class PseudoIdProvider {
  PseudoIdProvider(this.secretBytes, {this.uidVersion = 1});
  final List<int> secretBytes; // length >= 32
  final int uidVersion;

  /// Returns 22-char Base64URL without padding
  String generate(String rawUserId, {String namespace = 'svc'}) {
    final hmac = crypto.Hmac(crypto.sha256, secretBytes);
    final digest = hmac.convert(utf8.encode('$namespace:$rawUserId'));
    final b64 = base64UrlEncode(digest.bytes).replaceAll('=', '');
    return b64.substring(0, 22);
  }
}