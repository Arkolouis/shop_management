import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;
  final String name;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    DateTime? createdAt;

    final rawCreatedAt = data['createdAt'];

    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    }

    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? 'staff',
      name: data['name'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role, 'name': name, 'createdAt': createdAt};
  }
}
