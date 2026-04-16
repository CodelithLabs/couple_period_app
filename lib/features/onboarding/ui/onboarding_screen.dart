import 'package:couple_period_app/features/onboarding/model/onboarding_profile.dart';
import 'package:couple_period_app/features/onboarding/provider/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  late final TextEditingController _cycleLengthController;
  late final TextEditingController _periodDurationController;
  late final TextEditingController _inviteCodeController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(onboardingDraftProvider);
    _nameController = TextEditingController(text: profile.name);
    _relationshipController = TextEditingController(
      text: profile.relationshipStatus ?? '',
    );
    _cycleLengthController = TextEditingController(
      text: profile.cycleLength.toString(),
    );
    _periodDurationController = TextEditingController(
      text: profile.periodDuration.toString(),
    );
    _inviteCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _cycleLengthController.dispose();
    _periodDurationController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(onboardingDraftProvider);
    final step = ref.watch(onboardingStepProvider);
    final saveState = ref.watch(onboardingSaveControllerProvider);

    ref.listen<AsyncValue<void>>(onboardingSaveControllerProvider, (_, next) {
      if (!next.hasError) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.error.toString())));
    });

    final steps = _buildSteps(context, profile, saveState.isLoading);

    return Scaffold(
      appBar: AppBar(title: const Text('Setup your tracker')),
      body: Stepper(
        currentStep: step,
        type: StepperType.vertical,
        controlsBuilder: (context, details) {
          final isLast = step == steps.length - 1;
          return Row(
            children: [
              FilledButton(
                onPressed: saveState.isLoading
                    ? null
                    : () async {
                        if (isLast) {
                          _syncInputs();
                          await ref
                              .read(onboardingSaveControllerProvider.notifier)
                              .save(widget.userId);
                        } else {
                          _syncInputs();
                          ref.read(onboardingStepProvider.notifier).state =
                              step + 1;
                        }
                      },
                child: Text(isLast ? 'Finish' : 'Continue'),
              ),
              const SizedBox(width: 12),
              if (step > 0)
                TextButton(
                  onPressed: saveState.isLoading
                      ? null
                      : () {
                          ref.read(onboardingStepProvider.notifier).state =
                              step - 1;
                        },
                  child: const Text('Back'),
                ),
            ],
          );
        },
        steps: steps,
      ),
    );
  }

  List<Step> _buildSteps(
    BuildContext context,
    OnboardingProfile profile,
    bool loading,
  ) {
    return [
      Step(
        title: const Text('About you'),
        isActive: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              enabled: !loading,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AppGender>(
              initialValue: profile.gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: AppGender.values
                  .map(
                    (gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender.label),
                    ),
                  )
                  .toList(),
              onChanged: loading
                  ? null
                  : (value) {
                      if (value != null) {
                        ref
                            .read(onboardingDraftProvider.notifier)
                            .setGender(value);
                      }
                    },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AppMode>(
              initialValue: profile.mode,
              decoration: const InputDecoration(labelText: 'Mode'),
              items: AppMode.values
                  .map(
                    (mode) =>
                        DropdownMenuItem(value: mode, child: Text(mode.label)),
                  )
                  .toList(),
              onChanged: loading
                  ? null
                  : (value) {
                      if (value != null) {
                        ref
                            .read(onboardingDraftProvider.notifier)
                            .setMode(value);
                      }
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _relationshipController,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Relationship status (optional)',
              ),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Cycle setup'),
        isActive: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2010),
                        lastDate: DateTime.now(),
                        initialDate: profile.lastPeriodDate,
                      );
                      if (picked != null) {
                        ref
                            .read(onboardingDraftProvider.notifier)
                            .setLastPeriodDate(picked);
                      }
                    },
              icon: const Icon(Icons.calendar_today_rounded),
              label: Text(
                'Last period date: ${DateFormat.yMMMd().format(profile.lastPeriodDate)}',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cycleLengthController,
              enabled: !loading,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Average cycle length',
                helperText: 'Days (20-45)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _periodDurationController,
              enabled: !loading,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Period duration',
                helperText: 'Days (2-10)',
              ),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Health preferences'),
        isActive: true,
        content: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: profile.symptomsEnabled,
              onChanged: loading
                  ? null
                  : (value) => ref
                        .read(onboardingDraftProvider.notifier)
                        .setSymptomsEnabled(value),
              title: const Text('Enable symptoms tracking'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: profile.moodEnabled,
              onChanged: loading
                  ? null
                  : (value) => ref
                        .read(onboardingDraftProvider.notifier)
                        .setMoodEnabled(value),
              title: const Text('Enable mood tracking'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: profile.notificationsEnabled,
              onChanged: loading
                  ? null
                  : (value) => ref
                        .read(onboardingDraftProvider.notifier)
                        .setNotificationsEnabled(value),
              title: const Text('Enable notifications'),
            ),
          ],
        ),
      ),
      if (profile.mode == AppMode.couple)
        Step(
          title: const Text('Partner connection'),
          isActive: true,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.tonalIcon(
                onPressed: loading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final code = await ref
                              .read(partnerInviteServiceProvider)
                              .generateInviteCode(ownerUserId: widget.userId);
                          ref
                              .read(onboardingDraftProvider.notifier)
                              .setGeneratedInviteCode(code);
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Generate invite code'),
              ),
              if ((profile.generatedInviteCode ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  'Your invite code: ${profile.generatedInviteCode}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _inviteCodeController,
                enabled: !loading,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Enter partner invite code',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: loading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final partnerId = await ref
                              .read(partnerInviteServiceProvider)
                              .redeemInviteCode(
                                code: _inviteCodeController.text.trim(),
                                redeemerUserId: widget.userId,
                              );
                          ref
                              .read(onboardingDraftProvider.notifier)
                              .setPartnerId(partnerId);
                          if (!context.mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Partner linked successfully.'),
                            ),
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
                icon: const Icon(Icons.link_rounded),
                label: const Text('Redeem invite code'),
              ),
            ],
          ),
        ),
    ];
  }

  void _syncInputs() {
    final notifier = ref.read(onboardingDraftProvider.notifier);
    notifier.setName(_nameController.text);
    notifier.setRelationshipStatus(_relationshipController.text);

    final cycleLength = int.tryParse(_cycleLengthController.text) ?? 28;
    notifier.setCycleLength(cycleLength);

    final periodDuration = int.tryParse(_periodDurationController.text) ?? 5;
    notifier.setPeriodDuration(periodDuration);
  }
}
