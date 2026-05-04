import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Stream<List<AppUser>> getUsers() {
    return _db.collection('users').snapshots().map((snap) {
      return snap.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }
}
