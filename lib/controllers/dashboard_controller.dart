import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  double todaySales = 0;
  int totalProducts = 0;
  int lowStock = 0;
  int totalSalesToday = 0;

  double weeklySales = 0;
  int weeklyTransactions = 0;
  double monthlySales = 0;
  int monthlyTransactions = 0;
  double yearlySales = 0;
  int yearlyTransactions = 0;

  List<MapEntry<String, int>> topProducts = [];
  List<MapEntry<String, int>> leastProducts = [];

  double staffTodaySales = 0;
  int staffTransactionsToday = 0;
  double staffAverageSaleValue = 0;
  String mostSoldProduct = 'None';
  String lastSaleTime = 'No sales yet';
  double lastSaleAmount = 0;
  List<Map<String, dynamic>> lowStockProducts = [];

  bool isLoading = false;
  bool isInitialized = false;

  final List<dynamic> _subscriptions = [];

  void startListening() {
    if (isInitialized) return;
    isInitialized = true;

    isLoading = true;
    notifyListeners();

    _listenToProducts();
    _listenToTodaySales();
    _listenToWeeklySales();
    _listenToMonthlySales();
    _listenToYearlySales();
  }

  void _listenToProducts() {
    final sub = _db.collection('products').snapshots().listen((snapshot) {
      totalProducts = snapshot.docs.length;

      lowStock = snapshot.docs.where((doc) {
        final stock = (doc.data()['stock'] ?? 0) as num;
        return stock < 5;
      }).length;

      lowStockProducts = snapshot.docs
          .where((doc) {
            final stock = (doc.data()['stock'] ?? 0) as num;
            return stock < 5;
          })
          .map(
            (doc) => {
              'name': doc.data()['name'] ?? 'Unknown',
              'stock': (doc.data()['stock'] ?? 0) as num,
            },
          )
          .toList();

      isLoading = false;
      notifyListeners();
    });
    _subscriptions.add(sub);
  }

  void _listenToTodaySales() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final sub = _db
        .collection('sales')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .snapshots()
        .listen((snapshot) {
          totalSalesToday = snapshot.docs.length;
          staffTransactionsToday = snapshot.docs.length;

          todaySales = snapshot.docs.fold(0.0, (value, doc) {
            return value + ((doc.data()['total'] ?? 0) as num).toDouble();
          });

          staffTodaySales = todaySales;
          staffAverageSaleValue = staffTransactionsToday > 0
              ? staffTodaySales / staffTransactionsToday
              : 0;

          final Map<String, int> productCount = {};
          for (final doc in snapshot.docs) {
            final items = List<Map<String, dynamic>>.from(
              doc.data()['items'] ?? [],
            );
            for (final item in items) {
              final name = item['name'] as String? ?? 'Unknown';
              final qty = (item['qty'] as num?)?.toInt() ?? 1;
              productCount[name] = (productCount[name] ?? 0) + qty;
            }
          }

          if (productCount.isNotEmpty) {
            mostSoldProduct = productCount.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
          } else {
            mostSoldProduct = 'No sales yet';
          }

          if (snapshot.docs.isNotEmpty) {
            final sorted = snapshot.docs.toList()
              ..sort((a, b) {
                final aDate = a.data()['date'];
                final bDate = b.data()['date'];
                if (aDate == null || bDate == null) return 0;
                return (bDate as Timestamp).compareTo(aDate as Timestamp);
              });

            final lastDoc = sorted.first.data();
            lastSaleAmount = (lastDoc['total'] ?? 0).toDouble();
            final lastDate = lastDoc['date'];
            if (lastDate != null) {
              final dt = (lastDate as Timestamp).toDate();
              lastSaleTime =
                  "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            }
          } else {
            lastSaleTime = 'No sales yet';
            lastSaleAmount = 0;
          }

          isLoading = false;
          notifyListeners();
        });
    _subscriptions.add(sub);
  }

  void _listenToWeeklySales() {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );

    final sub = _db
        .collection('sales')
        .where('date', isGreaterThanOrEqualTo: startOfWeek)
        .snapshots()
        .listen((snapshot) {
          weeklyTransactions = snapshot.docs.length;
          weeklySales = snapshot.docs.fold(0.0, (value, doc) {
            return value + ((doc.data()['total'] ?? 0) as num).toDouble();
          });

          _computeProductPerformance(snapshot.docs);

          notifyListeners();
        });
    _subscriptions.add(sub);
  }

  void _listenToMonthlySales() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final sub = _db
        .collection('sales')
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .snapshots()
        .listen((snapshot) {
          monthlyTransactions = snapshot.docs.length;
          monthlySales = snapshot.docs.fold(0.0, (value, doc) {
            return value + ((doc.data()['total'] ?? 0) as num).toDouble();
          });
          notifyListeners();
        });
    _subscriptions.add(sub);
  }

  void _listenToYearlySales() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);

    final sub = _db
        .collection('sales')
        .where('date', isGreaterThanOrEqualTo: startOfYear)
        .snapshots()
        .listen((snapshot) {
          yearlyTransactions = snapshot.docs.length;
          yearlySales = snapshot.docs.fold(0.0, (value, doc) {
            return value + ((doc.data()['total'] ?? 0) as num).toDouble();
          });
          notifyListeners();
        });
    _subscriptions.add(sub);
  }

  void _computeProductPerformance(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, int> productCount = {};

    for (final doc in docs) {
      final items = List<Map<String, dynamic>>.from(doc.data()['items'] ?? []);
      for (final item in items) {
        final name = item['name'] as String? ?? 'Unknown';
        final qty = (item['qty'] as num?)?.toInt() ?? 1;
        productCount[name] = (productCount[name] ?? 0) + qty;
      }
    }

    if (productCount.isNotEmpty) {
      final sorted = productCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      topProducts = sorted.take(5).toList();

      leastProducts = sorted.reversed.take(5).toList();
    } else {
      topProducts = [];
      leastProducts = [];
    }
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
    weeklySales = 0;
    weeklyTransactions = 0;
    monthlySales = 0;
    monthlyTransactions = 0;
    yearlySales = 0;
    yearlyTransactions = 0;
    topProducts = [];
    leastProducts = [];
    staffTodaySales = 0;
    staffTransactionsToday = 0;
    staffAverageSaleValue = 0;
    mostSoldProduct = 'None';
    lastSaleTime = 'No sales yet';
    lastSaleAmount = 0;
    lowStockProducts = [];
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
