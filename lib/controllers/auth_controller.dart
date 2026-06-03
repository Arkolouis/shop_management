import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  User? user;
  String? role;
  String? userName;
  String? _preservedEmail;
  String? _preservedPassword;

  bool isLoading = false;
  bool roleLoading = false;

  AuthController() {
    _auth.authStateChanges().listen((u) async {
      user = u;

      if (u != null) {
        await loadUserRole();
      } else {
        role = null;
        roleLoading = false;
      }

      notifyListeners();
    });
  }

  Future<void> loadUserRole() async {
    if (user == null) return;

    try {
      roleLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('users').doc(user!.uid).get();

      if (!doc.exists) {
        role = null;
      } else {
        role = doc.data()?['role'] as String?;
        userName = doc.data()?['name'] as String?;
      }
    } catch (e) {
      role = null;
    } finally {
      roleLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login() async {
    try {
      isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      _preservedEmail = emailController.text.trim();
      _preservedPassword = passwordController.text.trim();

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signupWithRole(String role) async {
    try {
      isLoading = true;
      notifyListeners();

      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<T> runWithPreservedSession<T>(Future<T> Function() action) async {
    final previousUid = _auth.currentUser?.uid;
    final preservedEmail = _preservedEmail;
    final preservedPassword = _preservedPassword;

    final result = await action();

    if (previousUid != null &&
        _auth.currentUser?.uid != previousUid &&
        preservedEmail != null &&
        preservedPassword != null) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: preservedEmail,
          password: preservedPassword,
        );
      } catch (e) {
        debugPrint('Failed to restore admin session: $e');
      }
    }

    return result;
  }

  Future<void> logout() async {
    _preservedEmail = null;
    _preservedPassword = null;
    role = null;
    user = null;
    userName = null;
    roleLoading = false;
    notifyListeners();
    await _auth.signOut();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}
