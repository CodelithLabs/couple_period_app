import 'package:couple_period_app/features/mood/provider/mood_provider.dart';
import 'package:couple_period_app/features/partner/provider/partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  static const _emojiOptions = ['😊', '🙂', '😐', '😞', '😢', '😭', '😡', '😰'];

  String _selectedEmoji = '🙂';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentMoodState = ref.watch(moodRecentLogsProvider);
    final todayMood = ref.watch(moodTodayProvider);
    final suggestionState = ref.watch(moodSupportSuggestionProvider);
    final partnerState = ref.watch(partnerSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mood & Support')),
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
                    'How are you feeling right now?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _emojiOptions.map((emoji) {
                      final selected = _selectedEmoji == emoji;
                      return ChoiceChip(
                        label: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedEmoji = emoji;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'What feels hardest right now?',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref
                            .read(moodLogControllerProvider.notifier)
                            .addMood(
                              emoji: _selectedEmoji,
                              note: _noteController.text.trim().isEmpty
                                  ? null
                                  : _noteController.text.trim(),
                            );
                        if (!context.mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Mood check-in saved.')),
                        );
                      } catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
                    icon: const Icon(Icons.favorite_rounded),
                    label: const Text('Save mood check-in'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todayMood == null
                        ? 'No mood check-in yet today.'
                        : 'Today: ${todayMood.emoji} ${todayMood.note ?? ''}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: suggestionState.when(
                data: (text) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support suggestion',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(text),
                    ],
                  );
                },
                error: (error, _) => Text('Could not load suggestions: $error'),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          partnerState.when(
            data: (partner) {
              if (partner == null) {
                return const SizedBox.shrink();
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Couple sync',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Partner: ${partner.partnerName ?? 'Connected partner'}',
                      ),
                      if (partner.latestMoodEmoji != null)
                        Text('Latest partner mood: ${partner.latestMoodEmoji}'),
                      if (partner.currentPhase != null)
                        Text('Partner phase: ${partner.currentPhase}'),
                      const SizedBox(height: 6),
                      Text(partner.supportTip ?? ''),
                    ],
                  ),
                ),
              );
            },
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Text(
            'Recent mood logs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          recentMoodState.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No mood logs yet.'),
                  ),
                );
              }
              return Column(
                children: logs.take(7).map((log) {
                  return Card(
                    child: ListTile(
                      title: Text('${log.emoji} ${log.note ?? ''}'),
                      subtitle: Text(
                        DateFormat.yMMMd().add_jm().format(log.loggedAt),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to load mood history: $error'),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
