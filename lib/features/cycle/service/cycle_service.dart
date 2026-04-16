import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_period_app/core/utils/date_time_utils.dart';
import 'package:couple_period_app/features/cycle/model/cycle_snapshot.dart';

class CycleService {
  CycleService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<CycleSnapshot> getCycleSnapshot({required String userId}) async {
    final userCycles = _firestore
        .collection('users')
        .doc(userId)
        .collection('cycles');

    final settingsRef = userCycles.doc('settings');
    final settingsSnapshot = await settingsRef.get();

    var cycleLength = 28;
    var periodDuration = 5;
    var lastPeriodDate = DateTime.now();

    if (settingsSnapshot.exists) {
      final data = settingsSnapshot.data();
      cycleLength = (data?['cycleLength'] as int?) ?? 28;
      periodDuration = (data?['periodDuration'] as int?) ?? 5;
      lastPeriodDate =
          _parseFirestoreDate(data?['lastPeriodDate']) ?? DateTime.now();
    } else {
      final now = DateTime.now();
      final defaultDate = DateTime(now.year, now.month, now.day);
      await settingsRef.set({
        'cycleLength': cycleLength,
        'periodDuration': periodDuration,
        'lastPeriodDate': Timestamp.fromDate(
          DateTimeUtils.toUtcDate(defaultDate),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      lastPeriodDate = defaultDate;
    }

    final currentCycleStart = _calculateCurrentCycleStart(
      lastPeriodDate,
      cycleLength,
    );
    final predictedNextPeriodStart = currentCycleStart.add(
      Duration(days: cycleLength),
    );
    final ovulationDate = currentCycleStart.add(
      Duration(days: cycleLength - 14),
    );
    final fertileWindowStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileWindowEnd = ovulationDate.add(const Duration(days: 1));

    final logsQuery = await userCycles
        .where('kind', isEqualTo: 'periodLog')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    final recentLogs = logsQuery.docs.map((doc) {
      final data = doc.data();
      return PeriodLogEntry(
        id: doc.id,
        startDate: _parseFirestoreDate(data['startDate']) ?? DateTime.now(),
        endDate: _parseFirestoreDate(data['endDate']),
        flowLevel: (data['flowLevel'] as String?) ?? 'Medium',
        painLevel: (data['painLevel'] as int?) ?? 0,
        note: data['note'] as String?,
        createdAt: _parseFirestoreDate(data['createdAt']) ?? DateTime.now(),
      );
    }).toList();

    final currentPhase = _phaseForDate(
      date: DateTime.now(),
      currentCycleStart: currentCycleStart,
      cycleLength: cycleLength,
      periodDuration: periodDuration,
      ovulationDate: ovulationDate,
    );

    return CycleSnapshot(
      userId: userId,
      cycleLength: cycleLength,
      periodDuration: periodDuration,
      lastPeriodDate: lastPeriodDate,
      currentCycleStart: currentCycleStart,
      predictedNextPeriodStart: predictedNextPeriodStart,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
      currentPhase: currentPhase,
      recentLogs: recentLogs,
      supportMessage: _supportMessageForPhase(currentPhase),
    );
  }

  Future<void> logPeriodEntry({
    required String userId,
    required DateTime startDate,
    DateTime? endDate,
    required int painLevel,
    required String flowLevel,
    String? note,
  }) async {
    final userCycles = _firestore
        .collection('users')
        .doc(userId)
        .collection('cycles');

    await userCycles.add({
      'kind': 'periodLog',
      'startDate': Timestamp.fromDate(DateTimeUtils.toUtcDate(startDate)),
      'endDate': endDate == null
          ? null
          : Timestamp.fromDate(DateTimeUtils.toUtcDate(endDate)),
      'painLevel': painLevel,
      'flowLevel': flowLevel,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await userCycles.doc('settings').set({
      'lastPeriodDate': Timestamp.fromDate(DateTimeUtils.toUtcDate(startDate)),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DateTime _calculateCurrentCycleStart(
    DateTime lastPeriodDate,
    int cycleLength,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var currentStart = DateTime(
      lastPeriodDate.year,
      lastPeriodDate.month,
      lastPeriodDate.day,
    );

    while (true) {
      final next = currentStart.add(Duration(days: cycleLength));
      if (next.isAfter(today)) {
        return currentStart;
      }
      currentStart = next;
    }
  }

  CyclePhase _phaseForDate({
    required DateTime date,
    required DateTime currentCycleStart,
    required int cycleLength,
    required int periodDuration,
    required DateTime ovulationDate,
  }) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final cycleStartOnly = DateTime(
      currentCycleStart.year,
      currentCycleStart.month,
      currentCycleStart.day,
    );
    final ovulationOnly = DateTime(
      ovulationDate.year,
      ovulationDate.month,
      ovulationDate.day,
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

  String _supportMessageForPhase(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Your body is doing hard work today. Hydrate, use a warm compress, and prioritize gentle rest. If pain feels intense, consider reaching out to someone you trust.';
      case CyclePhase.follicular:
        return 'Energy may be rising. Keep your meals balanced, stay hydrated, and use this phase for light planning without overloading yourself.';
      case CyclePhase.ovulation:
        return 'You may feel more energetic or emotionally sensitive. Keep water intake up and pause for a few deep breaths when stress spikes.';
      case CyclePhase.luteal:
        return 'This can be an emotionally and physically heavy window. Reduce pressure, sleep earlier, eat warm nourishing meals, and ask for support when needed.';
    }
  }

  DateTime? _parseFirestoreDate(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate().toLocal();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
