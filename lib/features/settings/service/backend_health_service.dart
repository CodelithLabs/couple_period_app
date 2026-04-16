import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_period_app/features/settings/model/backend_health_report.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class BackendHealthService {
  BackendHealthService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<BackendHealthReport> runChecks() async {
    final checks = <BackendHealthCheck>[];

    checks.add(
      BackendHealthCheck(
        id: 'firebase_app_initialized',
        label: 'Firebase initialized',
        status: Firebase.apps.isNotEmpty
            ? BackendCheckStatus.pass
            : BackendCheckStatus.fail,
        message: Firebase.apps.isNotEmpty
            ? 'Firebase core is initialized.'
            : 'No Firebase app instance found.',
      ),
    );

    final user = _auth.currentUser;
    if (user == null) {
      checks.add(
        const BackendHealthCheck(
          id: 'auth_user_session',
          label: 'Authentication session',
          status: BackendCheckStatus.fail,
          message: 'No signed-in user found. Sign in with Google to continue.',
        ),
      );

      return BackendHealthReport(
        generatedAt: DateTime.now().toUtc(),
        checks: checks,
      );
    }

    checks.add(
      BackendHealthCheck(
        id: 'auth_user_session',
        label: 'Authentication session',
        status: BackendCheckStatus.pass,
        message: 'Signed in as ${user.email ?? user.uid}.',
      ),
    );

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        checks.add(
          const BackendHealthCheck(
            id: 'firestore_user_doc_read',
            label: 'Firestore user profile read',
            status: BackendCheckStatus.pass,
            message: 'Able to read user profile document.',
          ),
        );
      } else {
        checks.add(
          const BackendHealthCheck(
            id: 'firestore_user_doc_read',
            label: 'Firestore user profile read',
            status: BackendCheckStatus.warning,
            message: 'User profile document does not exist yet.',
          ),
        );
      }
    } catch (error) {
      checks.add(
        BackendHealthCheck(
          id: 'firestore_user_doc_read',
          label: 'Firestore user profile read',
          status: BackendCheckStatus.fail,
          message: 'Read failed: $error',
        ),
      );
    }

    try {
      final cycleDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cycles')
          .doc('settings')
          .get();
      checks.add(
        BackendHealthCheck(
          id: 'firestore_cycle_access',
          label: 'Cycle feature backend access',
          status: BackendCheckStatus.pass,
          message: cycleDoc.exists
              ? 'Cycle settings are accessible.'
              : 'Cycle settings are accessible (not configured yet).',
        ),
      );
    } catch (error) {
      checks.add(
        BackendHealthCheck(
          id: 'firestore_cycle_access',
          label: 'Cycle feature backend access',
          status: BackendCheckStatus.fail,
          message: 'Cycle access failed: $error',
        ),
      );
    }

    try {
      final moodLog = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .doc('journal')
          .collection('logs')
          .limit(1)
          .get();
      checks.add(
        BackendHealthCheck(
          id: 'firestore_mood_access',
          label: 'Mood feature backend access',
          status: BackendCheckStatus.pass,
          message: moodLog.docs.isEmpty
              ? 'Mood logs are accessible (no entries yet).'
              : 'Mood logs are accessible.',
        ),
      );
    } catch (error) {
      checks.add(
        BackendHealthCheck(
          id: 'firestore_mood_access',
          label: 'Mood feature backend access',
          status: BackendCheckStatus.fail,
          message: 'Mood access failed: $error',
        ),
      );
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('private_notes')
          .doc('system_health')
          .set({
            'lastCheckedAt': FieldValue.serverTimestamp(),
            'source': 'phase5_readiness_check',
          }, SetOptions(merge: true));

      checks.add(
        const BackendHealthCheck(
          id: 'firestore_write_probe',
          label: 'Firestore write probe',
          status: BackendCheckStatus.pass,
          message: 'Able to write diagnostics note under private_notes.',
        ),
      );
    } catch (error) {
      checks.add(
        BackendHealthCheck(
          id: 'firestore_write_probe',
          label: 'Firestore write probe',
          status: BackendCheckStatus.fail,
          message: 'Write probe failed: $error',
        ),
      );
    }

    return BackendHealthReport(
      generatedAt: DateTime.now().toUtc(),
      checks: checks,
    );
  }
}
