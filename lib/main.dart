import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/files_screen.dart';

void main() {
  runApp(const FileDropApp());
}

class FileDropApp extends StatelessWidget {
  const FileDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Drop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFF5A623), // matches the web app's accent color
        brightness: Brightness.dark,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFF5A623),
        brightness: Brightness.dark,
      ),
      home: const _AuthGate(),
    );
  }
}

/// Checks whether we already have saved credentials and, if so, verifies
/// they're wired up before deciding which screen to land on.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (loggedIn) {
      // Rebuild the shared ApiClient from stored credentials before showing FilesScreen.
      await ApiClient.create();
    }
    if (mounted) setState(() { _loggedIn = loggedIn; _checking = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? const FilesScreen() : const LoginScreen();
  }
}
