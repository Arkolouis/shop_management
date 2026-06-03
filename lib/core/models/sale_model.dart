import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String id;
  final double total;
  final DateTime date;
  final List<Map<String, dynamic>> items;
  final String? paymentMethod;

  Sale({
    required this.id,
    required this.total,
    required this.date,
    required this.items,
    this.paymentMethod,
  });

  factory Sale.fromFirestore(Map<String, dynamic> data, String id) {
    final rawDate = data['date'];
    DateTime parsedDate;

    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is Map<String, dynamic>) {
      final seconds = rawDate['_seconds'] ?? rawDate['seconds'];
      final nanoseconds =
          rawDate['_nanoseconds'] ?? rawDate['nanoseconds'] ?? rawDate['nanos'];
      if (seconds is int && nanoseconds is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + nanoseconds ~/ 1000000,
        );
      } else {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return Sale(
      id: id,
      total: (data['total'] as num).toDouble(),
      date: parsedDate,
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      paymentMethod: data['paymentMethod'] as String?,
    );
  }
}
