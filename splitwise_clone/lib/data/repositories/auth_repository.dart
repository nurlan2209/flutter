import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          friends: [],
          groups: [],
          createdAt: DateTime.now(),
          settings: {
            'theme': 'light',
            'defaultCurrency': 'USD',
            'notifications': true,
          },
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(user.toMap());

        return user;
      }
      return null;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (doc.exists) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      }
      return null;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Obtain the auth details from the request
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user exists in Firestore
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!doc.exists) {
          // Create new user document
          final user = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'Пользователь',
            photoUrl: userCredential.user!.photoURL,
            friends: [],
            groups: [],
            createdAt: DateTime.now(),
            settings: {
              'theme': 'light',
              'defaultCurrency': 'RUB',
              'notifications': true,
            },
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(user.toMap());

          return user;
        } else {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      }
      return null;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Пароль слишком простой';
        case 'email-already-in-use':
          return 'Email уже используется';
        case 'invalid-email':
          return 'Неверный формат email';
        case 'user-not-found':
          return 'Пользователь не найден';
        case 'wrong-password':
          return 'Неверный пароль';
        default:
          return 'Ошибка аутентификации: ${error.message}';
      }
    }
    return 'Произошла ошибка';
  }
}