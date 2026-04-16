import 'package:cloud_firestore/cloud_firestore.dart';

class MoodLog {
  const MoodLog({
    required this.id,
    required this.emoji,
    this.note,
    required this.loggedAt,
  });

  final String id;
  final String emoji;
  final String? note;
  final DateTime loggedAt;

  static MoodLog fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['loggedAt'] as Timestamp?;
    return MoodLog(
      id: id,
      emoji: (data['emoji'] as String?) ?? '🙂',
      note: data['note'] as String?,
      loggedAt: ts?.toDate().toLocal() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'emoji': emoji,
      'note': note,
      'loggedAt': Timestamp.fromDate(loggedAt.toUtc()),
    };
  }
}
