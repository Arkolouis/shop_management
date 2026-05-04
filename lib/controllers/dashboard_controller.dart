import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  double todaySales = 0;
  int totalProducts = 0;
  int lowStock = 0;
  int totalSalesToday = 0;

  bool isLoading = false;
  bool isInitialized = false;

  final List<dynamic> _subscriptions = [];

  void startListening() {
    if (isInitialized) return;
    isInitialized = true;

    isLoading = true;
    notifyListeners();

    final productsSub = _db.collection('products').snapshots().listen((
      snapshot,
    ) {
      totalProducts = snapshot.docs.length;

      lowStock = snapshot.docs.where((doc) {
        final stock = (doc.data()['stock'] ?? 0) as num;
        return stock < 5;
      }).length;

      isLoading = false;
      notifyListeners();
      debugPrint("📦 Dashboard products updated: $totalProducts");
    });

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final salesSub = _db
        .collection('sales')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .snapshots()
        .listen((snapshot) {
          totalSalesToday = snapshot.docs.length;

          todaySales = snapshot.docs.fold(0.0, (value, doc) {
            final amount = (doc.data()['total'] ?? 0) as num;
            return value + amount.toDouble();
          });

          isLoading = false;
          notifyListeners();
          debugPrint("💰 Dashboard sales updated: $todaySales");
        });

    _subscriptions.add(productsSub);
    _subscriptions.add(salesSub);
  }

  Future<void> refresh() async {
    isInitialized = false;
    _cancelSubscriptions();
    startListening();
  }

  void reset() {
    _cancelSubscriptions();
    todaySales = 0;
    totalProducts = 0;
    lowStock = 0;
    totalSalesToday = 0;
    isLoading = false;
    isInitialized = false;
    notifyListeners();
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
