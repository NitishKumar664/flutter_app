import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Simple polling refresh — no websocket wiring in this batch, keeps
    // the surface area (and risk) small while still feeling live.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final messages = await _chatService.listMessages();
      if (!mounted) return;
      setState(() => _messages = messages);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!silent && mounted) setState(() => _error = e.toString());
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _inputController.clear();
    try {
      await _chatService.sendMessage(text);
      await _load(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
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
      drawer: const AppDrawer(current: 'chat'),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load chat', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => _load(), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 48),
              const SizedBox(height: 12),
              Text('No messages yet', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('Messages from anyone using your links will show up here.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final m = _messages[index];
        return Align(
          alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: m.isMine
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!m.isMine)
                  Text(m.name, style: Theme.of(context).textTheme.labelSmall),
                Text(m.text ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                decoration: const InputDecoration(
                  hintText: 'Message anyone using your links…',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: _sending
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              onPressed: _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
