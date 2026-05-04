import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_management/controllers/auth_controller.dart';
import '../../widgets/custum_texfield.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String role = 'cashier'; // default role

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Create an account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              /// 👤 Name
              AppTextField(
                label: "Full Name",
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                controller: controller.nameController,
              ),
              const SizedBox(height: 16),

              /// 📧 Email (THIS is where TextInputType.emailAddress is used)
              AppTextField(
                label: "Email",
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress, // ✅ correct usage
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              /// 🔒 Password
              AppTextField(
                label: "Password",
                controller: controller.passwordController,
                obscure: true,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              /// 👑 Role Selector (IMPORTANT for your system)
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => role = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              /// 🔘 Signup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () async {
                          await controller.signupWithRole(role);
                        },
                  child: controller.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Sign Up"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
