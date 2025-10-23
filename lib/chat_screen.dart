import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'socket_service.dart';
import 'app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final SocketService socket;
  final String username;

  const ChatScreen({super.key, required this.socket, required this.username});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <String>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.socket.messages.listen((msg) {
      if (!mounted) return;
      setState(() => _messages.add(msg));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
    });
  }

  void _scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.socket.send(widget.username, text);
    _controller.clear();
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes != null) {
      widget.socket.sendFile(file.name, file.bytes!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: _messages.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(_messages[i]),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: l10n.typeMessage,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _sendFile,
                tooltip: l10n.attachFile,
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _send,
                tooltip: l10n.send,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
