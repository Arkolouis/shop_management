import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_management/data/services/user_services.dart';
import '../core/models/user_model.dart';

class AdminController extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();

  bool isLoading = false;

  Stream<List<AppUser>> get usersStream => _userService.getUsers();

  Future<void> createStaff({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      /// 🔥 Save to Firestore
      await _userService.createUser(
        AppUser(uid: cred.user!.uid, email: email, role: role),
      );
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
