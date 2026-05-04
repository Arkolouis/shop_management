import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (context.mounted) {
        context.go('/dashboard');
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

              /// Email
              AppTextField(
                label: "Email",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              /// Password
              AppTextField(
                label: "Password",
                controller: passwordController,
                obscure: true,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 24),

              /// Login Button
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

              /// Forgot password
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
