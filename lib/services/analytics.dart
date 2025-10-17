class Analytics {
  static void logEvent(String name, [Map<String, Object?> params = const {}]) {
    // Stub only: Connect to analytics later.
    // ignore: avoid_print
    print('[analytics] $name ${params.isEmpty ? '' : params}');
  }
}
