import 'dart:io';

class RuntimeInfo {
  RuntimeInfo({
    required this.build,
    required this.version,
    String? platform,
    String? osVersion,
    String? deviceName,
  })  : platform = platform ?? Platform.operatingSystem,
        osVersion = osVersion ?? Platform.operatingSystemVersion,
        deviceName = deviceName ?? _defaultDeviceName();

  final String build; // debug/profile/release
  final String version; // app version
  final String platform; // android/windows/linux
  final String osVersion;
  final String deviceName; // e.g., hostname or model if提供

  Map<String, Object?> toCtx() => {
        'build': build,
        'version': version,
        'platform': platform,
      };

  Map<String, Object?> toDevice() => {
        'os': platform[0].toUpperCase() + platform.substring(1),
        'osVersion': osVersion,
        'deviceName': deviceName,
      };

  static String _defaultDeviceName() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'unknown-device';
    }
  }
}