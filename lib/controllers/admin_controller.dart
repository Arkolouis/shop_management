import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_management/data/services/user_services.dart';
import 'package:shop_management/firebase_options.dart';
import '../core/models/user_model.dart';

class AdminController extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _userService = UserService();

  static const _secondaryAppName = 'admin-create-app';

  bool isLoading = false;
  String? errorMessage;

  Stream<List<AppUser>> get usersStream => _userService.getUsers();

  Future<FirebaseApp> _getSecondaryApp() async {
    try {
      return Firebase.app(_secondaryAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _secondaryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;
    FirebaseAuth? secondaryAuth;

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      secondaryApp = await _getSecondaryApp();
      secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ User created: $email");
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? e.code;
      throw Exception(errorMessage);
    } catch (e) {
      errorMessage = e.toString();
      throw Exception(errorMessage);
    } finally {
      if (secondaryAuth != null) {
        try {
          await secondaryAuth.signOut();
        } catch (_) {}
      }
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser({
    required String uid,
    required String name,
    required String role,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'role': role,
      });

      debugPrint("✅ User updated: $uid");
    } catch (e) {
      errorMessage = e.toString();
      throw Exception(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _firestore.collection('users').doc(uid).delete();
      debugPrint("✅ User deleted from Firestore: $uid");
    } catch (e) {
      errorMessage = e.toString();
      throw Exception(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
