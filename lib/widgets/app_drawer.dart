import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/files_screen.dart';
import '../screens/folders_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/contributors_screen.dart';

/// current: 'files' | 'folders' | 'chat' | 'settings' | 'contributors' —
/// highlights the active destination and no-ops if you tap the screen
/// you're already on.
class AppDrawer extends StatelessWidget {
  final String current;
  const AppDrawer({super.key, required this.current});

  void _go(BuildContext context, String route) {
    Navigator.pop(context); // close the drawer first
    if (route == current) return;
    Widget screen;
    switch (route) {
      case 'files':
        screen = const FilesScreen();
        break;
      case 'folders':
        screen = const FoldersScreen();
        break;
      case 'chat':
        screen = const ChatScreen();
        break;
      case 'settings':
        screen = const SettingsScreen();
        break;
      case 'contributors':
        screen = const ContributorsScreen();
        break;
      default:
        return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const DrawerHeader(
              child: Row(
                children: [
                  Icon(Icons.cloud_outlined, size: 32),
                  SizedBox(width: 12),
                  Text('File Drop', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            _tile(context, icon: Icons.folder_outlined, label: 'Files', route: 'files'),
            _tile(context, icon: Icons.folder_special_outlined, label: 'Folders', route: 'folders'),
            _tile(context, icon: Icons.chat_bubble_outline, label: 'Chat', route: 'chat'),
            _tile(context, icon: Icons.people_outline, label: 'Contributors', route: 'contributors'),
            _tile(context, icon: Icons.settings_outlined, label: 'Settings', route: 'settings'),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, {required IconData icon, required String label, required String route}) {
    final selected = route == current;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: () => _go(context, route),
    );
  }
}
