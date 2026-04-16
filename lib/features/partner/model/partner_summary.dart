class PartnerSummary {
  const PartnerSummary({
    required this.partnerId,
    this.partnerName,
    this.currentPhase,
    this.latestMoodEmoji,
    this.supportTip,
  });

  final String partnerId;
  final String? partnerName;
  final String? currentPhase;
  final String? latestMoodEmoji;
  final String? supportTip;
}
