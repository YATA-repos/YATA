// Minimal Level enum to satisfy references in enhanced_* log enums.

enum Level { trace, debug, info, warn, error, fatal }

extension LevelProps on Level {
  int get value => index;
  int get priority => index;
}
