import "dart:convert";

import "package:flutter_test/flutter_test.dart";

import "package:yata/infra/logging/formatters.dart";
import "package:yata/infra/logging/log_event.dart";
import "package:yata/infra/logging/log_level.dart";

void main() {
  final LogEvent event = LogEvent(
    ts: DateTime.utc(2025, 10, 10),
    lvl: LogLevel.debug,
    msg: "threshold triggered",
    tag: "omperf",
    fields: <String, dynamic>{"operation": "menu.load"},
    eventId: "evt-omperf",
  );

  test("コンソールフォーマッターがタグを出力する", () {
    final ConsolePrettyFormatter formatter = ConsolePrettyFormatter(
      useColor: false,
      useEmojiFallback: false,
    );

    final String line = formatter.format(event);

    expect(line, contains("(omperf)"));
    expect(line, contains("operation:menu.load"));
  });

  test("NdjsonフォーマッターがタグをJSONに含める", () {
    final NdjsonFormatter formatter = NdjsonFormatter();
    final Map<String, dynamic> json = jsonDecode(formatter.format(event)) as Map<String, dynamic>;

    expect(json["tag"], equals("omperf"));
    expect(json["fields"], containsPair("operation", "menu.load"));
  });
}
