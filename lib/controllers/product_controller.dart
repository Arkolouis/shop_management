import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shop_management/core/models/product_model.dart';

class ProductController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final imageAssetController = TextEditingController();

  bool isLoading = false;

  Stream<List<Product>> get productsStream =>
      _db.collection('products').snapshots().map((snapshot) {
        debugPrint("📦 Stream got ${snapshot.docs.length} products");
        return snapshot.docs
            .map((doc) => Product.fromFirestore(doc.data(), doc.id))
            .toList();
      });

  Future<String?> addProduct(String imageAssetName) async {
    try {
      isLoading = true;
      notifyListeners();

      final docRef = _db.collection('products').doc();

      await docRef.set({
        'name': nameController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0,
        'stock': int.tryParse(stockController.text.trim()) ?? 0,
        'imageAsset': imageAssetName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      clearForm();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProduct(Product product) async {
    try {
      isLoading = true;
      notifyListeners();

      await _db.collection('products').doc(product.id).update(product.toMap());
      debugPrint("✅ Product updated: ${product.id}");
      return null;
    } catch (e) {
      debugPrint("❌ Update Error: $e");
      return e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _db.collection('products').doc(id).delete();
      debugPrint("✅ Product deleted: $id");
    } catch (e) {
      debugPrint("❌ Delete Error: $e");
    }
  }

  void loadExistingImage(String? imageAsset) {
    imageAssetController.text = imageAsset ?? '';
    notifyListeners();
  }

  void clearForm() {
    nameController.clear();
    priceController.clear();
    stockController.clear();
    imageAssetController.clear();
  }

  void clearImageState() {
    imageAssetController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    imageAssetController.dispose();
    super.dispose();
  }
}
