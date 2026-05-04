import 'package:shop_management/core/models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  String get id => product.id;
  String get name => product.name;
  double get price => product.price;
  int get stock => product.stock;

  double get total => price * quantity;
}