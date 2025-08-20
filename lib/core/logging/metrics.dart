class LoggerCounters {
  int emitted = 0;
  int written = 0;
  int failed = 0;
  int retried = 0;
  int dropped = 0;
}

class LoggerGauges {
  int queueDepth = 0;
  int diskUsageMB = 0;
}

class LoggerTimers {
  double queueWaitP50Ms = 0;
  double queueWaitP95Ms = 0;
  double flushDurationP50Ms = 0;
  double flushDurationP95Ms = 0;
}

class LoggerStats {
  LoggerStats({
    required this.counters,
    required this.gauges,
    required this.timers,
  });
  final LoggerCounters counters;
  final LoggerGauges gauges;
  final LoggerTimers timers;
}