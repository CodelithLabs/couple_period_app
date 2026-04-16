import 'package:couple_period_app/features/auth/provider/auth_provider.dart';
import 'package:couple_period_app/features/onboarding/provider/onboarding_provider.dart';
import 'package:couple_period_app/features/partner/provider/partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PartnerScreen extends ConsumerStatefulWidget {
  const PartnerScreen({super.key});

  @override
  ConsumerState<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends ConsumerState<PartnerScreen> {
  final TextEditingController _redeemController = TextEditingController();
  bool _isGeneratingCode = false;
  bool _isRedeemingCode = false;

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partnerSummaryAsync = ref.watch(partnerSummaryProvider);
    final visibilityAsync = ref.watch(partnerVisibilityProvider);
    final actionState = ref.watch(partnerActionsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Connection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: partnerSummaryAsync.when(
                data: (summary) {
                  if (summary == null) {
                    return const Text(
                      'No partner connected yet. Generate an invite code or redeem one from your partner.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected with ${summary.partnerName}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current phase: ${summary.currentPhase ?? 'Unknown'}',
                      ),
                      Text(
                        'Latest mood: ${summary.latestMoodEmoji ?? 'Unavailable'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary.supportTip ??
                            'Stay connected with a short supportive message today.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Text('Failed to load partner data: $error'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInviteSection(context),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: visibilityAsync.when(
                data: (visibility) {
                  final shareCycle = visibility['shareCyclePhase'] ?? true;
                  final shareMood = visibility['shareMood'] ?? true;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partner Privacy Controls',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Share cycle phase with partner'),
                        value: shareCycle,
                        onChanged: actionState.isLoading
                            ? null
                            : (value) async {
                                await _updateVisibility(
                                  context,
                                  shareCyclePhase: value,
                                  shareMood: shareMood,
                                );
                              },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Share mood with partner'),
                        value: shareMood,
                        onChanged: actionState.isLoading
                            ? null
                            : (value) async {
                                await _updateVisibility(
                                  context,
                                  shareCyclePhase: shareCycle,
                                  shareMood: value,
                                );
                              },
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Text('Failed to load privacy controls: $error'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: actionState.isLoading
                ? null
                : () async {
                    await _confirmAndDisconnect(context);
                  },
            child: const Text('Disconnect Partner'),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite & Connect',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isGeneratingCode
                  ? null
                  : () async {
                      await _generateInviteCode(context);
                    },
              child: _isGeneratingCode
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate Invite Code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _redeemController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Redeem Invite Code',
                hintText: 'Enter 6-character code',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _isRedeemingCode
                  ? null
                  : () async {
                      await _redeemInviteCode(context);
                    },
              child: _isRedeemingCode
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Redeem Code'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateInviteCode(BuildContext context) async {
    setState(() {
      _isGeneratingCode = true;
    });
    try {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) {
        throw Exception('No authenticated user found.');
      }

      final code = await ref
          .read(partnerInviteServiceProvider)
          .generateInviteCode(ownerUserId: uid);
      if (!context.mounted) return;
      await Clipboard.setData(ClipboardData(text: code));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite code: $code (copied to clipboard)')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate invite code: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingCode = false;
        });
      }
    }
  }

  Future<void> _redeemInviteCode(BuildContext context) async {
    final rawCode = _redeemController.text.trim();
    if (rawCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-character code.')),
      );
      return;
    }

    setState(() {
      _isRedeemingCode = true;
    });

    try {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) {
        throw Exception('No authenticated user found.');
      }

      await ref
          .read(partnerInviteServiceProvider)
          .redeemInviteCode(code: rawCode, redeemerUserId: uid);
      if (!context.mounted) return;
      _redeemController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner linked successfully.')),
      );
      ref.invalidate(partnerSummaryProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to redeem code: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isRedeemingCode = false;
        });
      }
    }
  }

  Future<void> _updateVisibility(
    BuildContext context, {
    required bool shareCyclePhase,
    required bool shareMood,
  }) async {
    try {
      await ref
          .read(partnerActionsControllerProvider.notifier)
          .updateVisibility(
            shareCyclePhase: shareCyclePhase,
            shareMood: shareMood,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings updated.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update privacy settings: $error')),
      );
    }
  }

  Future<void> _confirmAndDisconnect(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disconnect partner?'),
          content: const Text(
            'This will remove your active couple link. You can reconnect later using a new invite code.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Disconnect'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(partnerActionsControllerProvider.notifier)
          .disconnectCouple();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Partner disconnected.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disconnect partner: $error')),
      );
    }
  }
}
