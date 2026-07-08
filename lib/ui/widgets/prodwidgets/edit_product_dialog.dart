import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/product_controller.dart';
import 'package:shop_management/core/models/product_model.dart';
import 'package:shop_management/ui/widgets/prodwidgets/product_images.dart';

void showEditProductDialog(BuildContext context, Product product) {
  context.read<ProductController>().loadExistingImage(product.imageAsset);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<ProductController>(),
      child: _EditProductDialog(product: product),
    ),
  );
}

class _EditProductDialog extends StatefulWidget {
  final Product product;
  const _EditProductDialog({required this.product});

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late String _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _priceCtrl = TextEditingController(text: widget.product.price.toString());
    _stockCtrl = TextEditingController(text: widget.product.stock.toString());

    _selectedImage = widget.product.imageAsset ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductController>();

    return AlertDialog(
      title: const Text("Edit Product"),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            _selectedImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Select an image below",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 10),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Available Images",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: productImages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final imagePath = productImages[index];
                      final isSelected = _selectedImage == imagePath;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedImage = imagePath);
                          controller.imageAssetController.text = imagePath;
                        },
                        child: Container(
                          width: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[300]!,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter name" : null,
                ),

                TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter price";
                    if (double.tryParse(v) == null) return "Invalid price";
                    return null;
                  },
                ),

                TextFormField(
                  controller: _stockCtrl,
                  decoration: const InputDecoration(labelText: "Stock"),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter stock";
                    if (int.tryParse(v) == null) return "Invalid stock";
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            context.read<ProductController>().clearForm();
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: controller.isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  if (_selectedImage.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select an image"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final updated = Product(
                    id: widget.product.id,
                    name: _nameCtrl.text.trim(),
                    price: double.parse(_priceCtrl.text),
                    stock: int.parse(_stockCtrl.text),
                    imageAsset: _selectedImage,
                  );

                  final error = await context
                      .read<ProductController>()
                      .updateProduct(updated);

                  if (error != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                    return;
                  }

                  if (context.mounted) {
                    context.read<ProductController>().clearForm();
                    Navigator.pop(context);
                  }
                },
          child: controller.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Update"),
        ),
      ],
    );
  }
}
