enum CyclePhase { menstrual, follicular, ovulation, luteal }

extension CyclePhaseX on CyclePhase {
  String get label {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }
}

class PeriodLogEntry {
  const PeriodLogEntry({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.flowLevel,
    required this.painLevel,
    this.note,
    required this.createdAt,
  });

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final String flowLevel;
  final int painLevel;
  final String? note;
  final DateTime createdAt;
}

class CycleSnapshot {
  const CycleSnapshot({
    required this.userId,
    required this.cycleLength,
    required this.periodDuration,
    required this.lastPeriodDate,
    required this.currentCycleStart,
    required this.predictedNextPeriodStart,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.currentPhase,
    required this.recentLogs,
    required this.supportMessage,
  });

  final String userId;
  final int cycleLength;
  final int periodDuration;
  final DateTime lastPeriodDate;
  final DateTime currentCycleStart;
  final DateTime predictedNextPeriodStart;
  final DateTime ovulationDate;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final CyclePhase currentPhase;
  final List<PeriodLogEntry> recentLogs;
  final String supportMessage;

  CyclePhase phaseForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final ovulationOnly = DateTime(
      ovulationDate.year,
      ovulationDate.month,
      ovulationDate.day,
    );
    final cycleStartOnly = DateTime(
      currentCycleStart.year,
      currentCycleStart.month,
      currentCycleStart.day,
    );

    final dayIndex = dateOnly.difference(cycleStartOnly).inDays;

    if (dayIndex >= 0 && dayIndex < periodDuration) {
      return CyclePhase.menstrual;
    }

    if (dateOnly.difference(ovulationOnly).inDays.abs() <= 1) {
      return CyclePhase.ovulation;
    }

    if (dayIndex >= cycleLength - 6 && dayIndex < cycleLength) {
      return CyclePhase.luteal;
    }

    return CyclePhase.follicular;
  }
}
