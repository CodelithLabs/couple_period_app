import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_period_app/features/onboarding/model/onboarding_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingService {
  OnboardingService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> saveProfile({
    required String userId,
    required String email,
    required OnboardingProfile profile,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);

    await userRef.set({
      ...profile.toUserMap(),
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await userRef
        .collection('cycles')
        .doc('settings')
        .set(profile.toCycleSettingsMap(), SetOptions(merge: true));

    await userRef.collection('moods').doc('preferences').set({
      'enabled': profile.moodEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<bool> watchCompletion(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return false;
      }
      return data['onboardingCompleted'] == true;
    });
  }

  Future<void> createUserIfMissing(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (snapshot.exists) {
      return;
    }

    await userRef.set({
      'name': user.displayName ?? '',
      'email': user.email,
      'onboardingCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
