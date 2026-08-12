import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'files_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController(text: 'http://');
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _serverController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    // Save first (ApiClient reads credentials from storage), then verify by
    // hitting a real authenticated endpoint — /api/storage exists for every
    // role (owner/admin/viewer), so it's a safe, lightweight ping.
    await AuthService.instance.saveCredentials(
      serverUrl: _serverController.text.trim(),
      username: _userController.text.trim(),
      password: _passController.text,
    );

    try {
      final client = await ApiClient.create();
      final res = await client.dio.get('/api/storage');
      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FilesScreen()),
        );
        return;
      }
      if (res.statusCode == 401) {
        setState(() => _error = 'Incorrect username or password.');
      } else {
        setState(() => _error = 'Server responded with ${res.statusCode}.');
      }
      await AuthService.instance.clear();
    } on DioException catch (e) {
      setState(() => _error = _describeDioError(e));
      await AuthService.instance.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _describeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Could not reach the server — check the URL and that it\'s running.';
      case DioExceptionType.connectionError:
        return 'Connection failed. If your server uses plain HTTP (not HTTPS), '
            'make sure cleartext traffic is allowed (see README-flutter.md).';
      default:
        return 'Login failed: ${e.message ?? 'unknown error'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.cloud_outlined, size: 56),
                  const SizedBox(height: 12),
                  Text('File Drop', style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Sign in to your server', style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _serverController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://your-server.example.com',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!v.startsWith('http://') && !v.startsWith('https://')) {
                        return 'Must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
