import 'package:couple_period_app/features/auth/provider/auth_provider.dart';
import 'package:couple_period_app/features/cycle/model/cycle_snapshot.dart';
import 'package:couple_period_app/features/cycle/provider/cycle_provider.dart';
import 'package:couple_period_app/features/cycle/ui/cycle_screen.dart';
import 'package:couple_period_app/features/mood/provider/mood_provider.dart';
import 'package:couple_period_app/features/mood/ui/mood_screen.dart';
import 'package:couple_period_app/features/settings/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final cycleState = ref.watch(cycleSnapshotProvider);
    final moodToday = ref.watch(moodTodayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome ${user?.name ?? 'there'}'),
                  const SizedBox(height: 8),
                  Text(user?.email ?? ''),
                  const SizedBox(height: 8),
                  const Text(
                    'Your health space is here for the hard days too. Track your cycle, understand what is happening, and get practical support quickly.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          cycleState.when(
            data: (snapshot) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cycle summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Current phase: ${snapshot.currentPhase.label}'),
                      const SizedBox(height: 4),
                      Text(
                        'Next period: ${DateFormat.yMMMd().format(snapshot.predictedNextPeriodStart)}',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CycleScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Open Cycle & Care'),
                      ),
                    ],
                  ),
                ),
              );
            },
            error: (_, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cycle data is not available yet.'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CycleScreen(),
                            ),
                          );
                        },
                        child: const Text('Open Cycle & Care'),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mood check-in',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    moodToday == null
                        ? 'No mood logged today yet.'
                        : 'Today\'s mood: ${moodToday.emoji} ${moodToday.note ?? ''}',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MoodScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mood_rounded),
                    label: const Text('Open Mood & Support'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
