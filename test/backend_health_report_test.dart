import 'package:couple_period_app/features/settings/model/backend_health_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backend report aggregates counts and readiness', () {
    final report = BackendHealthReport(
      generatedAt: DateTime.utc(2026, 4, 16),
      checks: const [
        BackendHealthCheck(
          id: 'a',
          label: 'A',
          status: BackendCheckStatus.pass,
          message: 'ok',
        ),
        BackendHealthCheck(
          id: 'b',
          label: 'B',
          status: BackendCheckStatus.warning,
          message: 'warn',
        ),
        BackendHealthCheck(
          id: 'c',
          label: 'C',
          status: BackendCheckStatus.fail,
          message: 'fail',
        ),
      ],
    );

    expect(report.passCount, 1);
    expect(report.warningCount, 1);
    expect(report.failCount, 1);
    expect(report.isReadyToShip, isFalse);
  });

  test('report is ready when there are no failures', () {
    final report = BackendHealthReport(
      generatedAt: DateTime.utc(2026, 4, 16),
      checks: const [
        BackendHealthCheck(
          id: 'a',
          label: 'A',
          status: BackendCheckStatus.pass,
          message: 'ok',
        ),
        BackendHealthCheck(
          id: 'b',
          label: 'B',
          status: BackendCheckStatus.warning,
          message: 'warn',
        ),
      ],
    );

    expect(report.isReadyToShip, isTrue);
  });
}
