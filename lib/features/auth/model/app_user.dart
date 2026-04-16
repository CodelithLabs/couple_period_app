import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? name;
  final String? photoUrl;

  factory AppUser.fromFirebase(User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
