import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerInviteService {
  PartnerInviteService(this._firestore);

  final FirebaseFirestore _firestore;
  static const _characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<String> generateInviteCode({required String ownerUserId}) async {
    final ownerRef = _firestore.collection('users').doc(ownerUserId);
    final ownerSnapshot = await ownerRef.get();
    final ownerData = ownerSnapshot.data();

    if ((ownerData?['partnerId'] as String?)?.isNotEmpty == true) {
      throw Exception('You are already connected to a partner.');
    }

    final existing = await _firestore
        .collection('invite_codes')
        .where('ownerUserId', isEqualTo: ownerUserId)
        .where('used', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final data = existing.docs.first.data();
      final expiresAt = data['expiresAt'] as Timestamp?;
      if (expiresAt != null &&
          expiresAt.toDate().isAfter(DateTime.now().toUtc())) {
        return existing.docs.first.id;
      }
    }

    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _buildCode();
      final ref = _firestore.collection('invite_codes').doc(code);
      final existing = await ref.get();
      if (existing.exists) {
        continue;
      }

      await ref.set({
        'ownerUserId': ownerUserId,
        'used': false,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().toUtc().add(const Duration(hours: 24)),
        ),
      });

      return code;
    }

    throw Exception('Unable to generate invite code. Try again.');
  }

  Future<String> redeemInviteCode({
    required String code,
    required String redeemerUserId,
  }) async {
    final normalized = code.trim().toUpperCase();
    final inviteRef = _firestore.collection('invite_codes').doc(normalized);
    final couplesRef = _firestore.collection('couples');

    return _firestore.runTransaction((transaction) async {
      final redeemerRef = _firestore.collection('users').doc(redeemerUserId);
      final redeemerSnapshot = await transaction.get(redeemerRef);
      final redeemerData = redeemerSnapshot.data();
      if ((redeemerData?['partnerId'] as String?)?.isNotEmpty == true) {
        throw Exception('You are already connected to a partner.');
      }

      final inviteSnapshot = await transaction.get(inviteRef);
      if (!inviteSnapshot.exists) {
        throw Exception('Invite code is invalid.');
      }

      final data = inviteSnapshot.data()!;
      final ownerUserId = data['ownerUserId'] as String;
      final used = data['used'] as bool? ?? false;
      final expiresAt = data['expiresAt'] as Timestamp?;

      if (ownerUserId == redeemerUserId) {
        throw Exception('You cannot use your own invite code.');
      }
      if (used) {
        throw Exception('Invite code was already used.');
      }
      if (expiresAt != null &&
          expiresAt.toDate().isBefore(DateTime.now().toUtc())) {
        throw Exception('Invite code has expired.');
      }

      final ownerRef = _firestore.collection('users').doc(ownerUserId);
      final ownerSnapshot = await transaction.get(ownerRef);
      final ownerData = ownerSnapshot.data();
      if ((ownerData?['partnerId'] as String?)?.isNotEmpty == true) {
        throw Exception('Invite owner is already connected to a partner.');
      }

      final coupleDoc = couplesRef.doc();
      transaction.set(coupleDoc, {
        'user1': ownerUserId,
        'user2': redeemerUserId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(ownerRef, {
        'partnerId': redeemerUserId,
        'mode': 'couple',
        'coupleId': coupleDoc.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(redeemerRef, {
        'partnerId': ownerUserId,
        'mode': 'couple',
        'coupleId': coupleDoc.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final ownerSettingsRef = ownerRef
          .collection('partner_settings')
          .doc('preferences');
      final redeemerSettingsRef = redeemerRef
          .collection('partner_settings')
          .doc('preferences');

      transaction.set(ownerSettingsRef, {
        'shareCyclePhase': true,
        'shareMood': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(redeemerSettingsRef, {
        'shareCyclePhase': true,
        'shareMood': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(inviteRef, {
        'used': true,
        'usedBy': redeemerUserId,
        'usedAt': FieldValue.serverTimestamp(),
        'coupleId': coupleDoc.id,
      }, SetOptions(merge: true));

      return ownerUserId;
    });
  }

  Future<void> disconnectCouple({required String userId}) async {
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final userData = userSnapshot.data();
      if (userData == null) {
        throw Exception('User profile not found.');
      }

      final partnerId = userData['partnerId'] as String?;
      final coupleId = userData['coupleId'] as String?;

      if (partnerId == null ||
          partnerId.isEmpty ||
          coupleId == null ||
          coupleId.isEmpty) {
        throw Exception('No active partner connection found.');
      }

      final partnerRef = _firestore.collection('users').doc(partnerId);
      final coupleRef = _firestore.collection('couples').doc(coupleId);

      transaction.set(userRef, {
        'partnerId': null,
        'coupleId': null,
        'mode': 'solo',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(partnerRef, {
        'partnerId': null,
        'coupleId': null,
        'mode': 'solo',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(coupleRef, {
        'status': 'disconnected',
        'disconnectedBy': userId,
        'disconnectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> setPartnerVisibility({
    required String userId,
    required bool shareCyclePhase,
    required bool shareMood,
  }) async {
    final settingsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('partner_settings')
        .doc('preferences');

    await settingsRef.set({
      'shareCyclePhase': shareCyclePhase,
      'shareMood': shareMood,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, bool>> watchPartnerVisibility({required String userId}) {
    final settingsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('partner_settings')
        .doc('preferences');

    return settingsRef.snapshots().map((doc) {
      final data = doc.data();
      return {
        'shareCyclePhase': (data?['shareCyclePhase'] as bool?) ?? true,
        'shareMood': (data?['shareMood'] as bool?) ?? true,
      };
    });
  }

  String _buildCode() {
    final random = Random.secure();
    return List.generate(
      6,
      (_) => _characters[random.nextInt(_characters.length)],
    ).join();
  }
}
