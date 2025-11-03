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
import 'widgets/message_content.dart';
import 'notification_service.dart';

enum ChatViewMode { list, bubble }

class ChatScreen extends StatefulWidget {
  final SocketService socket;
  final String username;
  final ValueNotifier<int>? settingsChangeNotifier;

  const ChatScreen({
    super.key,
    required this.socket,
    required this.username,
    this.settingsChangeNotifier,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <SocketMessage>[];
  StreamSubscription<SocketMessage>? _subscription;
  StreamSubscription<bool>? _connectionSubscription;
  ChatViewMode _viewMode = ChatViewMode.bubble;
  ChatColors? _colors;
  bool _markdownEnabled = true;
  bool _enterToSend = true;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _subscription = widget.socket.messages.listen((msg) {
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
      });
      _handleNotification(msg);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
    });
    _connectionSubscription = widget.socket.connectionStatus.listen((
      connected,
    ) {
      if (!mounted) return;
      setState(() {
        _isConnected = connected;
      });
      if (!connected) {
        _showDisconnectionDialog();
      }
    });
    widget.settingsChangeNotifier?.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
  }

  void _onSettingsChanged() {
    _loadSettings();
  }

  void _handleNotification(SocketMessage msg) {
    if (msg.type == 'text') {
      final chatMsg = ChatMessage.fromSocketMessage(msg, widget.username);
      if (chatMsg.type == MessageType.userMessage && !chatMsg.isMine) {
        NotificationService().showMessageNotification(
          chatMsg.sender,
          chatMsg.content,
        );
      }
    }
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modeIndex = prefs.getInt('chat_view_mode') ?? 1;
    final markdownEnabled = prefs.getBool('markdown_rendering') ?? true;
    final enterToSend = prefs.getBool('enter_to_send') ?? true;
    if (!mounted) return;
    setState(() {
      _viewMode = ChatViewMode.values[modeIndex];
      _markdownEnabled = markdownEnabled;
      _enterToSend = enterToSend;
    });

    final colors = await ChatColors.load(isDark);
    if (!mounted) return;
    setState(() {
      _colors = colors;
    });
  }

  void _showDisconnectionDialog() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text(l10n.connectionLost),
          content: Text(l10n.disconnectedFromServer),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.ok),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.settingsChangeNotifier?.removeListener(_onSettingsChanged);
    _subscription?.cancel();
    _connectionSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  String _translateMessage(ChatMessage msg, AppLocalizations l10n) {
    if (msg.type == MessageType.systemMessage &&
        msg.content == 'disconnected_from_server') {
      return l10n.disconnectedFromServer;
    }

    // 文件传输状态消息
    if (msg.type == MessageType.fileTransfer) {
      switch (msg.content) {
        case 'file_received':
          return l10n.fileReceived(msg.args.isNotEmpty ? msg.args[0] : '');
        case 'file_size_mismatch':
          return l10n.fileSizeMismatch;
        case 'cannot_create_dir':
          return l10n.cannotCreateDir(msg.args.isNotEmpty ? msg.args[0] : '');
        case 'cannot_get_dir':
          return l10n.cannotGetDir;
        case 'file_saved':
          return l10n.fileSaved(msg.args.isNotEmpty ? msg.args[0] : '');
        case 'file_save_failed':
          return l10n.fileSaveFailed(msg.args.isNotEmpty ? msg.args[0] : '');
        case 'receiving_file':
          return l10n.receivingFile(msg.args.isNotEmpty ? msg.args[0] : '');
        default:
          return msg.content; // fallback
      }
    }

    // 系统消息
    if (msg.type == MessageType.systemMessage && msg.content == 'user_joined') {
      return l10n.userJoined(msg.args.isNotEmpty ? msg.args[0] : '');
    }

    return msg.content;
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
          final l10n = AppLocalizations.of(context);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.fileSavedTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.fileLocation,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    filePath,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.fileLocationHint,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
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
                          SnackBar(content: Text(l10n.cannotOpenFile)),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.openFailed('$e'))),
                        );
                      }
                    }
                  },
                  child: Text(l10n.openFile),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.cannotOpenLocation('$e'))));
      }
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .forEach((line) => widget.socket.send(widget.username, line.trim()));

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
    final chatMessages = _messages
        .map((msg) => ChatMessage.fromSocketMessage(msg, widget.username))
        .toList();

    return Column(
      children: [
        if (!_isConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: Colors.red.shade900,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.signal_wifi_off,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.disconnectedFromServer,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        Expanded(
          child: _viewMode == ChatViewMode.bubble
              ? _buildBubbleView(chatMessages, colors, l10n)
              : _buildListView(chatMessages, colors, l10n),
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
                  maxLines: _enterToSend ? 1 : null,
                  onSubmitted: _enterToSend ? (_) => _send() : null,
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

  Widget _buildBubbleView(
    List<ChatMessage> messages,
    ChatColors colors,
    AppLocalizations l10n,
  ) {
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
                          _translateMessage(msg, l10n),
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
                  child: MessageContent(
                    text: _translateMessage(msg, l10n),
                    enableMarkdown: _markdownEnabled,
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(
    List<ChatMessage> messages,
    ChatColors colors,
    AppLocalizations l10n,
  ) {
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
                  child: MessageContent(
                    text: msg.content.isNotEmpty
                        ? (msg.type == MessageType.userMessage
                              ? '${msg.sender}: ${_translateMessage(msg, l10n)}'
                              : _translateMessage(msg, l10n))
                        : '',
                    enableMarkdown: _markdownEnabled,
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
}
