import 'package:couple_period_app/features/cycle/model/cycle_snapshot.dart';
import 'package:couple_period_app/features/cycle/provider/cycle_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CycleScreen extends ConsumerStatefulWidget {
  const CycleScreen({super.key});

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends ConsumerState<CycleScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final snapshotState = ref.watch(cycleSnapshotProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cycle & Care')),
      body: snapshotState.when(
        data: (snapshot) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(snapshot: snapshot),
              const SizedBox(height: 16),
              _buildCalendar(snapshot),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openLogBottomSheet(context),
                icon: const Icon(Icons.edit_calendar_rounded),
                label: const Text('Log period'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _openSupportBottomSheet(context, snapshot),
                icon: const Icon(Icons.favorite_rounded),
                label: const Text('I need support now'),
              ),
              const SizedBox(height: 16),
              Text(
                'Recent logs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (snapshot.recentLogs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No logs yet. Start by logging your current cycle day.',
                    ),
                  ),
                )
              else
                ...snapshot.recentLogs.map((entry) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${DateFormat.yMMMd().format(entry.startDate)} • ${entry.flowLevel} flow',
                      ),
                      subtitle: Text(
                        'Pain ${entry.painLevel}/10${entry.note == null || entry.note!.trim().isEmpty ? '' : ' • ${entry.note}'}',
                      ),
                    ),
                  );
                }),
            ],
          );
        },
        error: (error, _) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Unable to load cycle data: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildCalendar(CycleSnapshot snapshot) {
    final monthLabel = DateFormat.yMMMM().format(_visibleMonth);
    final firstDayOfMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );
    final dayOffset = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final totalCells = dayOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                _WeekdayLabel('S'),
                _WeekdayLabel('M'),
                _WeekdayLabel('T'),
                _WeekdayLabel('W'),
                _WeekdayLabel('T'),
                _WeekdayLabel('F'),
                _WeekdayLabel('S'),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows * 7,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, index) {
                final day = index - dayOffset + 1;
                if (day <= 0 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month,
                  day,
                );
                final phase = snapshot.phaseForDate(date);
                final color = _phaseColor(phase);
                final isToday = DateUtils.isSameDay(date, DateTime.now());

                return Padding(
                  padding: const EdgeInsets.all(3),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: CyclePhase.values.map((phase) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _phaseColor(phase),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(phase.label),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _phaseColor(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return const Color(0xFFE57373);
      case CyclePhase.follicular:
        return const Color(0xFF81C784);
      case CyclePhase.ovulation:
        return const Color(0xFFFFD54F);
      case CyclePhase.luteal:
        return const Color(0xFF9575CD);
    }
  }

  Future<void> _openLogBottomSheet(BuildContext context) async {
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    var painLevel = 4.0;
    var flowLevel = 'Medium';
    final noteController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Log period',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(2010),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          initialDate: startDate,
                        );
                        if (picked != null) {
                          setModalState(() {
                            startDate = picked;
                          });
                        }
                      },
                      child: Text(
                        'Start: ${DateFormat.yMMMd().format(startDate)}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(2010),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                          initialDate: endDate ?? startDate,
                        );
                        if (picked != null) {
                          setModalState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Text(
                        endDate == null
                            ? 'End: Optional'
                            : 'End: ${DateFormat.yMMMd().format(endDate!)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Pain level: ${painLevel.round()}/10'),
                    Slider(
                      value: painLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: '${painLevel.round()}',
                      onChanged: (value) {
                        setModalState(() {
                          painLevel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: flowLevel,
                      decoration: const InputDecoration(labelText: 'Flow'),
                      items: const ['Light', 'Medium', 'Heavy']
                          .map(
                            (flow) => DropdownMenuItem(
                              value: flow,
                              child: Text(flow),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            flowLevel = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(cycleLogControllerProvider.notifier)
                              .logPeriod(
                                startDate: startDate,
                                endDate: endDate,
                                painLevel: painLevel.round(),
                                flowLevel: flowLevel,
                                note: noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim(),
                              );
                          if (!ctx.mounted) {
                            return;
                          }
                          Navigator.of(ctx).pop();
                          if (!mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Period log saved.')),
                          );
                        } catch (error) {
                          if (!ctx.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                      child: const Text('Save log'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    noteController.dispose();
  }

  Future<void> _openSupportBottomSheet(
    BuildContext context,
    CycleSnapshot snapshot,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support right now',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(snapshot.supportMessage),
                const SizedBox(height: 12),
                const Text(
                  '• Drink warm water and breathe slowly for 60 seconds.',
                ),
                const Text('• Use a warm pad on your lower abdomen.'),
                const Text(
                  '• Keep tasks light and ask for support if pain is intense.',
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.snapshot});

  final CycleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current phase: ${snapshot.currentPhase.label}'),
            const SizedBox(height: 6),
            Text(
              'Next period: ${DateFormat.yMMMd().format(snapshot.predictedNextPeriodStart)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Fertile window: ${DateFormat.MMMd().format(snapshot.fertileWindowStart)} - ${DateFormat.MMMd().format(snapshot.fertileWindowEnd)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(value, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}
