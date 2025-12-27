import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref("users");

  /// Register user and save username in Realtime Database
  Future<User?> register(String username, String email, String password) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;

    await _db.child(uid).set({
      "uid": uid,
      "username": username,
      "email": email,
    });

    return userCredential.user;
  }

  /// Sign in
  Future<User?> signIn(String email, String password) async {
    UserCredential userCredential =
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
