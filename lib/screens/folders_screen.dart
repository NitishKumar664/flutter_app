import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/file_item.dart';
import '../models/folder_item.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';
import '../services/folder_service.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final _folderService = FolderService();
  final _fileService = FileService();
  List<FolderItem> _folders = [];
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
      final folders = await _folderService.listFolders();
      setState(() => _folders = folders);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteFolder(FolderItem folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text('"${folder.name}" and every file inside it will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _folderService.deleteFolder(folder.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _openFolder(FolderItem folder) async {
    List<FileItem> allFiles;
    try {
      allFiles = await _fileService.listFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load files: $e')));
      }
      return;
    }
    final filesInFolder = allFiles.where((f) => f.folderId == folder.id).toList();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(folder.name, style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(
              child: filesInFolder.isEmpty
                  ? const Center(child: Text('This folder is empty'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filesInFolder.length,
                      itemBuilder: (ctx, i) => ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(filesInFolder[i].originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
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
      drawer: const AppDrawer(current: 'folders'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _folders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _folders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load folders', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_folders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open_outlined, size: 48),
              const SizedBox(height: 12),
              Text('No folders yet', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'Folders are created by uploading a whole folder from the web dashboard.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          final f = _folders[index];
          return ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${f.source == 'shared' ? 'From contributor link' : 'Uploaded by you'} · '
              '${DateFormat.yMMMd().format(f.createdAt)}${f.hasPassword ? ' · Password protected' : ''}',
            ),
            onTap: () => _openFolder(f),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteFolder(f),
            ),
          );
        },
      ),
    );
  }
}
