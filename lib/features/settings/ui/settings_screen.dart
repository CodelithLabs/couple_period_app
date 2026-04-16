import 'package:couple_period_app/features/auth/provider/auth_provider.dart';
import 'package:couple_period_app/features/settings/model/backend_health_report.dart';
import 'package:couple_period_app/features/settings/provider/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider).value;
    final appSettingsAsync = ref.watch(settingsProvider);
    final healthAsync = ref.watch(backendHealthControllerProvider);
    final healthReport = healthAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Readiness')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(appUser?.name ?? 'Unknown user'),
                  const SizedBox(height: 4),
                  Text(appUser?.email ?? 'No email available'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: appSettingsAsync.when(
                data: (settings) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Preferences',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.notificationsEnabled
                            ? 'Notifications: Enabled'
                            : 'Notifications: Disabled',
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Failed to load settings: $error'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firebase Backend Health',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Runs live diagnostics for Firebase initialization, auth session, Firestore read/write, and feature access.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: healthAsync.isLoading
                        ? null
                        : () async {
                            await ref
                                .read(backendHealthControllerProvider.notifier)
                                .runChecks();
                          },
                    icon: const Icon(Icons.health_and_safety_rounded),
                    label: const Text('Run Backend Check'),
                  ),
                  if (healthAsync.isLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (healthAsync.hasError) ...[
                    const SizedBox(height: 12),
                    Text('Diagnostics failed: ${healthAsync.error}'),
                  ],
                  if (healthReport != null) ...[
                    const SizedBox(height: 12),
                    _HealthSummary(report: healthReport),
                    const SizedBox(height: 8),
                    for (final check in healthReport.checks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _HealthCheckTile(check: check),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phase 5 Release Checklist',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildChecklistItem(
                    context,
                    title: 'Static analysis and tests',
                    subtitle:
                        'Run flutter analyze and flutter test before every release candidate.',
                  ),
                  _buildChecklistItem(
                    context,
                    title: 'Firebase rules and indexes deployed',
                    subtitle:
                        'Deploy Firestore rules/indexes with Firebase CLI before production rollout.',
                  ),
                  _buildChecklistItem(
                    context,
                    title: 'Crash and analytics monitoring',
                    subtitle:
                        'Connect monitoring stack before scaling to 1000+ devices.',
                  ),
                  _buildChecklistItem(
                    context,
                    title: 'Run backend check in this screen',
                    subtitle:
                        'Use the diagnostic card to validate auth and Firestore access on a release build.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle_outline_rounded),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle),
    );
  }
}

class _HealthSummary extends StatelessWidget {
  const _HealthSummary({required this.report});

  final BackendHealthReport report;

  @override
  Widget build(BuildContext context) {
    final statusText = report.isReadyToShip
        ? 'Backend status: Ready'
        : 'Backend status: Action needed';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statusText, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            'Pass: ${report.passCount} • Warning: ${report.warningCount} • Fail: ${report.failCount}',
          ),
          const SizedBox(height: 6),
          Text('Checked at: ${report.generatedAt.toLocal()}'),
        ],
      ),
    );
  }
}

class _HealthCheckTile extends StatelessWidget {
  const _HealthCheckTile({required this.check});

  final BackendHealthCheck check;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (check.status) {
      BackendCheckStatus.pass => (Icons.check_circle, Colors.green),
      BackendCheckStatus.warning => (Icons.warning_rounded, Colors.orange),
      BackendCheckStatus.fail => (Icons.error_rounded, Colors.red),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(check.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
