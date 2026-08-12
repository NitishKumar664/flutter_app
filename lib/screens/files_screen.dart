import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/file_item.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';
import 'login_screen.dart';
import '../widgets/app_drawer.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _fileService = FileService();
  List<FileItem> _files = [];
  int _usedBytes = 0;
  int? _limitBytes;
  bool _loading = true;
  String? _error;
  double? _uploadProgress; // null = no upload in progress

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final files = await _fileService.listFiles();
      final storage = await _fileService.getStorage();
      setState(() {
        _files = files;
        _usedBytes = storage.$1;
        _limitBytes = storage.$2;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    setState(() => _uploadProgress = 0);
    try {
      await _fileService.uploadFile(file, onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploaded')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadProgress = null);
    }
  }

  Future<void> _deleteFile(FileItem file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('"${file.originalName}" will be permanently deleted.'),
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
      await _fileService.deleteFile(file.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  IconData _iconFor(FileItem f) {
    if (f.isImage) return Icons.image_outlined;
    if (f.isVideo) return Icons.videocam_outlined;
    if (f.isPdf) return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Sign out'),
        ],
      ),
      drawer: const AppDrawer(current: 'files'),
      body: Column(
        children: [
          if (_uploadProgress != null)
            LinearProgressIndicator(value: _uploadProgress == 0 ? null : _uploadProgress),
          if (_limitBytes != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _limitBytes! > 0 ? (_usedBytes / _limitBytes!).clamp(0.0, 1.0).toDouble() : 0.0,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatSize(_usedBytes)} of ${_formatSize(_limitBytes!)} used',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadProgress != null ? null : _pickAndUpload,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load files', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.upload_file_outlined, size: 48),
              const SizedBox(height: 12),
              Text('No files yet', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('Tap + to upload your first file', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final f = _files[index];
          return ListTile(
            leading: Icon(_iconFor(f)),
            title: Text(f.originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${_formatSize(f.size)} · ${DateFormat.yMMMd().add_jm().format(f.uploadedAt)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteFile(f),
            ),
          );
        },
      ),
    );
  }
}
