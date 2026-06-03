import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/auth_controller.dart';
import 'package:shop_management/ui/pages/forgotpassword/forgot_password_page.dart';
import '../../widgets/custum_texfield.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<void> login(BuildContext context) async {
    isLoading.value = true;

    try {
      final authController = context.read<AuthController>();
      authController.emailController.text = emailController.text.trim();
      authController.passwordController.text = passwordController.text.trim();

      final error = await authController.login();
      if (error != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Login failed: $error")));
        }
      } else {
        if (context.mounted) {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${e.toString()}")),
        );
      }
    }

    isLoading.value = false;
  }

  Future<void> resetPassword(BuildContext context) async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ForgotPasswordPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Login to your account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              AppTextField(
                label: "Email",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: "Email Address"),
              ),

              const SizedBox(height: 16),

              AppTextField(
                label: "Password",

                controller: passwordController,
                obscure: true,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: "Password"),
              ),

              const SizedBox(height: 24),

              ValueListenableBuilder(
                valueListenable: isLoading,
                builder: (context, loading, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : () => login(context),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login"),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => resetPassword(context),
                child: const Text("Forgot Password?"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
