enum BackendCheckStatus { pass, warning, fail }

class BackendHealthCheck {
  const BackendHealthCheck({
    required this.id,
    required this.label,
    required this.status,
    required this.message,
  });

  final String id;
  final String label;
  final BackendCheckStatus status;
  final String message;
}

class BackendHealthReport {
  const BackendHealthReport({required this.generatedAt, required this.checks});

  final DateTime generatedAt;
  final List<BackendHealthCheck> checks;

  int get passCount =>
      checks.where((check) => check.status == BackendCheckStatus.pass).length;

  int get warningCount => checks
      .where((check) => check.status == BackendCheckStatus.warning)
      .length;

  int get failCount =>
      checks.where((check) => check.status == BackendCheckStatus.fail).length;

  bool get isReadyToShip => failCount == 0;
}
