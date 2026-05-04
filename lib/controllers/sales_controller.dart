import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_management/features/cart/cart_item.dart';
import 'package:shop_management/core/models/sale_model.dart';
import 'package:shop_management/core/models/product_model.dart';

class StockException implements Exception {
  final String message;
  StockException(this.message);

  @override
  String toString() => message;
}

class SalesController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, CartItem> _cart = {};

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Stream<List<Sale>> get salesStream {
    return _firestore
        .collection('sales')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Sale.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  bool canAddToCart(Product product) {
    final item = _cart[product.id];

    if (product.stock <= 0) return false;

    if (item != null) {
      return item.quantity < product.stock;
    }

    return true;
  }

  List<CartItem> get cart => _cart.values.toList();

  double get total =>
      _cart.values.fold(0.0, (value, item) => value + item.total);

  void addToCart(Product product) {
    if (product.stock <= 0) {
      throw StockException('${product.name} is out of stock!');
    }

    if (_cart.containsKey(product.id)) {
      final item = _cart[product.id]!;

      if (item.quantity >= product.stock) {
        throw StockException(
          'Only ${product.stock} ${product.name} available.',
        );
      }

      item.quantity++;
    } else {
      _cart[product.id] = CartItem(product: product);
    }

    notifyListeners();
  }

  void increaseQty(String productId) {
    final item = _cart[productId];
    if (item == null) return;

    if (item.quantity >= item.stock) {
      throw StockException('Only ${item.stock} ${item.name} available.');
    }

    item.quantity++;
    notifyListeners();
  }

  void decreaseQty(String productId) {
    final item = _cart[productId];
    if (item == null) return;

    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _cart.remove(productId);
    }

    notifyListeners();
  }

  void removeItem(String productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  Future<Map<String, dynamic>> checkout() async {
    if (_cart.isEmpty) throw StockException("Cart is empty");

    try {
      _setProcessing(true);

      Map<String, dynamic> receipt = {};

      await _firestore.runTransaction((transaction) async {
        final saleRef = _firestore.collection('sales').doc();

        for (final item in _cart.values) {
          final docRef = _firestore.collection('products').doc(item.id);
          final doc = await transaction.get(docRef);

          final currentStock = (doc['stock'] as num).toInt();

          if (currentStock < item.quantity) {
            throw StockException(
              'Only $currentStock ${item.name} left in stock',
            );
          }
        }

        final receiptDate = DateTime.now();
        receipt = {
          'id': saleRef.id,
          'date': receiptDate,
          'total': total,
          'items': _cart.values.map((item) {
            return {
              'name': item.name,
              'price': item.price,
              'qty': item.quantity,
              'subtotal': item.total,
            };
          }).toList(),
        };

        transaction.set(saleRef, {
          ...receipt,
          'date': FieldValue.serverTimestamp(),
        });

        for (final item in _cart.values) {
          final docRef = _firestore.collection('products').doc(item.id);

          transaction.update(docRef, {
            'stock': FieldValue.increment(-item.quantity),
          });
        }
      });

      _cart.clear();
      notifyListeners();

      return receipt;
    } catch (e) {
      rethrow;
    } finally {
      _setProcessing(false);
    }
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
}
