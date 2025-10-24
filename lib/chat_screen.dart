import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'socket_service.dart';
import 'app_localizations.dart';
import 'models/chat_message.dart';
import 'models/chat_colors.dart';

enum ChatViewMode { list, bubble }

class ChatScreen extends StatefulWidget {
  final SocketService socket;
  final String username;
  final List<String> messages;

  const ChatScreen({
    super.key,
    required this.socket,
    required this.username,
    required this.messages,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  ChatViewMode _viewMode = ChatViewMode.bubble;
  ChatColors? _colors;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modeIndex = prefs.getInt('chat_view_mode') ?? 1;
    if (!mounted) return;
    setState(() {
      _viewMode = ChatViewMode.values[modeIndex];
    });

    final colors = await ChatColors.load(isDark);
    if (!mounted) return;
    setState(() {
      _colors = colors;
    });
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  void _scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _openFilePath(String filePath) async {
    try {
      final file = File(filePath);
      final directory = file.parent.path;

      if (Platform.isWindows) {
        final uri = Uri.parse('file:///$filePath');
        await launchUrl(uri);
      } else if (Platform.isMacOS) {
        final uri = Uri.parse('file://$directory');
        await launchUrl(uri);
      } else if (Platform.isLinux) {
        final uri = Uri.parse('file://$directory');
        await launchUrl(uri);
      } else if (Platform.isAndroid) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('文件已保存'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '文件位置:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    filePath,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '提示: 您可以在文件管理器中找到此文件',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final fileUri = Uri.file(filePath);
                      final launched = await launchUrl(
                        fileUri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!launched && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('无法打开文件，请在文件管理器中查找')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('打开失败: $e')));
                      }
                    }
                  },
                  child: const Text('打开文件'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法打开文件位置: $e')));
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _colors ?? (isDark ? ChatColors.dark() : ChatColors.light());
    final chatMessages = widget.messages
        .map((raw) => ChatMessage.parse(raw, widget.username))
        .toList();

    return Column(
      children: [
        Expanded(
          child: _viewMode == ChatViewMode.bubble
              ? _buildBubbleView(chatMessages, colors)
              : _buildListView(chatMessages, colors),
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

  Widget _buildBubbleView(List<ChatMessage> messages, ChatColors colors) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];

        if (msg.type == MessageType.systemMessage ||
            msg.type == MessageType.fileTransfer) {
          final isBan =
              msg.content.contains('封禁') || msg.content.contains('ban');
          final bgColor = isBan ? colors.banNotification : colors.systemMessage;
          final isClickable = msg.filePath != null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: InkWell(
                onTap: isClickable ? () => _openFilePath(msg.filePath!) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isClickable
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isClickable)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.folder_open,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          msg.content,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isClickable
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Align(
            alignment: msg.isMine
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: msg.isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!msg.isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                    child: Text(
                      msg.sender,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isMine
                        ? colors.myMessageBubble
                        : colors.otherMessageBubble,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    msg.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<ChatMessage> messages, ChatColors colors) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];

        Color? bgColor;
        if (msg.type == MessageType.systemMessage ||
            msg.type == MessageType.fileTransfer) {
          final isBan =
              msg.content.contains('封禁') || msg.content.contains('ban');
          bgColor = isBan ? colors.banNotification : colors.systemMessage;
        } else if (msg.type == MessageType.userMessage) {
          bgColor = msg.isMine
              ? colors.myMessageBubble
              : colors.otherMessageBubble;
        }

        final isClickable = msg.filePath != null;

        return InkWell(
          onTap: isClickable ? () => _openFilePath(msg.filePath!) : null,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: isClickable
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (isClickable)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.folder_open,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                Expanded(
                  child: Text(
                    msg.content.isNotEmpty
                        ? (msg.type == MessageType.userMessage
                              ? '${msg.sender}: ${msg.content}'
                              : msg.content)
                        : '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isClickable
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
