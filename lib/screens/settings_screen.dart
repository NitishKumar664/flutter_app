import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  final _appNameController = TextEditingController();
  final _storageLimitController = TextEditingController();
  String _defaultExpiry = '';
  bool _memberAuthEnabled = false;
  bool _nearbyShareEnabled = false;
  bool _supportEnabled = false;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  static const _expiryOptions = {'': 'Never', '24': '24 hours', '168': '7 days', '720': '30 days'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _storageLimitController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await _settingsService.getSettings();
      setState(() {
        _appNameController.text = s.appName;
        _storageLimitController.text = s.storageLimitMb?.toString() ?? '';
        _defaultExpiry = _expiryOptions.containsKey(s.defaultExpiryHours) ? s.defaultExpiryHours : '';
        _memberAuthEnabled = s.memberAuthEnabled;
        _nearbyShareEnabled = s.nearbyShareEnabled;
        _supportEnabled = s.supportEnabled;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveGeneral() async {
    setState(() => _saving = true);
    try {
      await _settingsService.updateGeneral(
        appName: _appNameController.text.trim(),
        defaultExpiryHours: _defaultExpiry,
        storageLimitMb: int.tryParse(_storageLimitController.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleFeature(String which, bool value) async {
    setState(() {
      switch (which) {
        case 'memberAuth': _memberAuthEnabled = value; break;
        case 'nearbyShare': _nearbyShareEnabled = value; break;
        case 'support': _supportEnabled = value; break;
      }
    });
    try {
      await _settingsService.updateFeatureFlags(
        memberAuthEnabled: which == 'memberAuth' ? value : null,
        nearbyShareEnabled: which == 'nearbyShare' ? value : null,
        supportEnabled: which == 'support' ? value : null,
      );
    } catch (e) {
      // Revert on failure and let the user know
      setState(() {
        switch (which) {
          case 'memberAuth': _memberAuthEnabled = !value; break;
          case 'nearbyShare': _nearbyShareEnabled = !value; break;
          case 'support': _supportEnabled = !value; break;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
      drawer: const AppDrawer(current: 'settings'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load settings', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text(
                'Note: only Owner/Admin accounts can view settings — a Viewer account will always get this error.',
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('General', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _appNameController,
          decoration: const InputDecoration(labelText: 'App name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _defaultExpiry,
          decoration: const InputDecoration(labelText: 'Default expiry for new uploads', border: OutlineInputBorder()),
          items: _expiryOptions.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => setState(() => _defaultExpiry = v ?? ''),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _storageLimitController,
          decoration: const InputDecoration(labelText: 'Storage limit (MB)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _saveGeneral,
          child: _saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
        const Divider(height: 40),
        Text('Features', style: Theme.of(context).textTheme.titleMedium),
        SwitchListTile(
          title: const Text('User accounts'),
          subtitle: const Text('Registration, login, friends & DMs'),
          value: _memberAuthEnabled,
          onChanged: (v) => _toggleFeature('memberAuth', v),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Nearby Share'),
          value: _nearbyShareEnabled,
          onChanged: (v) => _toggleFeature('nearbyShare', v),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Customer Support'),
          value: _supportEnabled,
          onChanged: (v) => _toggleFeature('support', v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),
        Text(
          'Storage backend (S3/R2), email (SMTP), and AI settings involve '
          'secrets and more complex forms — manage those from the web dashboard for now.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
