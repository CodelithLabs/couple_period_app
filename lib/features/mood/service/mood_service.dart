import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_period_app/features/mood/model/mood_log.dart';

class MoodService {
  MoodService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> addMood({
    required String userId,
    required String emoji,
    String? note,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final journalRef = userRef.collection('moods').doc('journal');

    await journalRef.collection('logs').add({
      'emoji': emoji,
      'note': note,
      'loggedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await journalRef.set({
      'lastEmoji': emoji,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<MoodLog>> watchRecentMoods({
    required String userId,
    int limit = 14,
  }) {
    final logsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .doc('journal')
        .collection('logs');

    return logsRef
        .orderBy('loggedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MoodLog.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<MoodLog?> getLatestMood({required String userId}) async {
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .doc('journal')
        .collection('logs')
        .orderBy('loggedAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    final doc = query.docs.first;
    return MoodLog.fromFirestore(doc.id, doc.data());
  }

  Future<String> buildSupportSuggestion({required String userId}) async {
    final latestMood = await getLatestMood(userId: userId);
    if (latestMood == null) {
      return 'No mood logged yet. Start with one emoji check-in so we can tailor your support.';
    }

    var latestPainLevel = 0;
    try {
      final cycleLog = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cycles')
          .where('kind', isEqualTo: 'periodLog')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (cycleLog.docs.isNotEmpty) {
        latestPainLevel =
            (cycleLog.docs.first.data()['painLevel'] as int?) ?? 0;
      }
    } catch (_) {
      latestPainLevel = 0;
    }

    final emoji = latestMood.emoji;
    if ((emoji == '😢' || emoji == '😭' || emoji == '😞') &&
        latestPainLevel >= 7) {
      return 'This looks like a very hard day. Pause for 60 seconds of slow breathing, drink warm water, use heat for pain relief, and message your partner or trusted person for support.';
    }

    if (emoji == '😡' || emoji == '😰' || emoji == '😵') {
      return 'Your stress load seems high. Try a short reset: unclench shoulders, take 10 deep breaths, and reduce non-urgent tasks for today.';
    }

    if (emoji == '😐' || emoji == '🙂') {
      return 'You are doing okay. Keep hydration up, eat regularly, and schedule one calm break today to protect your energy.';
    }

    if (emoji == '😊' || emoji == '😍' || emoji == '😁') {
      return 'Great to see a positive check-in. Keep your routine steady and use this window to prepare for upcoming lower-energy days.';
    }

    return 'Take it gently today. Hydrate, rest as needed, and ask for support when your body feels overloaded.';
  }
}
