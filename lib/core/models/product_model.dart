class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String? imageAsset;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.imageAsset,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? 'Unnamed Product',
      price: (data['price'] ?? 0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      imageAsset: data['imageAsset'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
      'imageAsset': imageAsset,
    };
  }
}
