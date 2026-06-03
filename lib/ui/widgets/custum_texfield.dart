import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? error;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    required this.keyboardType,
    required this.textInputAction,
    this.error,
    required InputDecoration decoration,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool isObscured;

  @override
  void initState() {
    super.initState();
    isObscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: isObscured,

      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.error,

        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                ),

                onPressed: () {
                  setState(() {
                    isObscured = !isObscured;
                  });
                },
              )
            : null,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
