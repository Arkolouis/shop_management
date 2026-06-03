import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../core/models/user_model.dart';

class AdminUsersBody extends StatefulWidget {
  const AdminUsersBody({super.key});

  @override
  State<AdminUsersBody> createState() => _AdminUsersBodyState();
}

class _AdminUsersBodyState extends State<AdminUsersBody> {
  String _searchQuery = '';
  String _filterRole = 'all';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search by name or email...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterRole,
                        items: ['all', 'admin', 'manager', 'staff']
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                  r == 'all' ? 'All Roles' : r,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _filterRole = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: controller.usersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  final allUsers = snapshot.data ?? [];

                  final users = allUsers.where((user) {
                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        user.name.toLowerCase().contains(_searchQuery) ||
                        user.email.toLowerCase().contains(_searchQuery);

                    final matchesRole =
                        _filterRole == 'all' || user.role == _filterRole;

                    return matchesSearch && matchesRole;
                  }).toList();

                  if (users.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "No users found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _userCard(context, user, controller);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text("Add User"),
          ),
        ),
      ],
    );
  }

  Widget _userCard(
    BuildContext context,
    AppUser user,
    AdminController controller,
  ) {
    final roleColor =
        {
          'admin': Colors.red,
          'manager': Colors.blue,
          'staff': Colors.green,
        }[user.role] ??
        Colors.grey;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(
                user.name.isNotEmpty
                    ? user.name[0].toUpperCase()
                    : user.email[0].toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : 'No name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  // role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: roleColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                if (action == 'edit') {
                  _showEditDialog(context, user);
                } else if (action == 'delete') {
                  _showDeleteDialog(context, user, controller);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text("Edit"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Delete", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role = 'staff';
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final controller = context.read<AdminController>();

          return AlertDialog(
            title: const Text("Add New User"),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Full Name"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter name" : null,
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter email";
                        if (!v.contains('@')) return "Invalid email";
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Enter password";
                        }
                        if (v.length < 6) {
                          return "Minimum 6 characters";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: "Role"),
                      items: ['admin', 'manager', 'staff']
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (val) => setDialogState(() => role = val!),
                    ),
                  ],
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        try {
                          await controller.createUser(
                            name: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            password: passwordCtrl.text.trim(),
                            role: role,
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ User created"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: controller.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, AppUser user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.name);
    String role = user.role;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final controller = context.read<AdminController>();

          return AlertDialog(
            title: const Text("Edit User"),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: user.email,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Email",
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Full Name"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter name" : null,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: "Role"),
                      items: ['admin', 'manager', 'staff']
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (val) => setDialogState(() => role = val!),
                    ),
                  ],
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        try {
                          await controller.updateUser(
                            uid: user.uid,
                            name: nameCtrl.text.trim(),
                            role: role,
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ User updated"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    AppUser user,
    AdminController controller,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Are you sure you want to delete this user?"),
            const SizedBox(height: 12),
            Text(
              user.name.isNotEmpty ? user.name : user.email,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(user.email, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This removes the user from the system. They will no longer be able to log in.",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await controller.deleteUser(user.uid);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ User deleted"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
