import 'package:flutter/material.dart';
import '../models/user_item.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';

class ContributorsScreen extends StatefulWidget {
  const ContributorsScreen({super.key});

  @override
  State<ContributorsScreen> createState() => _ContributorsScreenState();
}

class _ContributorsScreenState extends State<ContributorsScreen> {
  final _userService = UserService();
  List<UserItem> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final users = await _userService.listUsers();
      setState(() => _users = users);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteUser(UserItem user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove contributor?'),
        content: Text('"${user.username}" will lose access immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _userService.deleteUser(user.username);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remove failed: $e')));
      }
    }
  }

  Future<void> _showAddDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'viewer';
    String? dialogError;

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add contributor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin — can upload, delete, manage')),
                    DropdownMenuItem(value: 'viewer', child: Text('Viewer — read-only')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v ?? 'viewer'),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(dialogError!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final username = usernameController.text.trim();
                final password = passwordController.text;
                if (username.isEmpty || password.isEmpty) {
                  setDialogState(() => dialogError = 'Username and password are required');
                  return;
                }
                try {
                  await _userService.addUser(username: username, password: password, role: role);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  setDialogState(() => dialogError = e.toString());
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    usernameController.dispose();
    passwordController.dispose();
    if (added == true) await _load();
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'owner':
        return Icons.star_outline;
      case 'admin':
        return Icons.shield_outlined;
      default:
        return Icons.visibility_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await AuthService.instance.clear();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(current: 'contributors'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.person_add_outlined),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load contributors', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text(
                'Note: only the Owner account can view contributors.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final u = _users[index];
          return ListTile(
            leading: Icon(_roleIcon(u.role)),
            title: Text(u.username),
            subtitle: Text(u.role[0].toUpperCase() + u.role.substring(1)),
            trailing: u.builtin
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteUser(u),
                  ),
          );
        },
      ),
    );
  }
}
