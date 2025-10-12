import "package:flutter_test/flutter_test.dart";

import "package:yata/infra/logging/log_config.dart";
import "package:yata/infra/logging/log_level.dart";

void main() {
  test("LogConfig.defaults が omperf タグのレベルを設定する", () {
    final LogConfig config = LogConfig.defaults(fileDirPath: "/tmp");

    expect(config.tagLevels["omperf"], equals(LogLevel.debug));
  });
}
