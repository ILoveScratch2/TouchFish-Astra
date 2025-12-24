import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final Function(List<ChatMessage>)? onMessagesChanged;

  const ChatScreen({
    super.key,
    required this.socket,
    required this.username,
    this.settingsChangeNotifier,
    this.onMessagesChanged,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _messages = <SocketMessage>[];
  StreamSubscription<SocketMessage>? _subscription;
  ChatViewMode _viewMode = ChatViewMode.bubble;
  ChatColors? _colors;
  bool _markdownEnabled = true;
  bool _enterToSend = true;
  bool _autoScroll = true;
  bool _autoSaveFiles = true;
  int _chatTarget = -1; // -1 = public, >= 0 = private chat with UID

  List<ChatMessage> get chatMessages => _messages
      .map((msg) => ChatMessage.fromSocketMessage(msg, widget.socket.myUid))
      .toList();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _subscription = widget.socket.messages.listen((msg) {
      if (!mounted) return;
      if (msg.type == 'SERVER.DATA') {
        _loadChatHistoryIfEnabled(msg);
        _showEnterHintIfExists(msg);
      }
      
      setState(() {
        _messages.add(msg);
      });
      _handleNotification(msg);
      final chatMsg = ChatMessage.fromSocketMessage(msg, widget.socket.myUid);
      if (_autoSaveFiles && chatMsg.isFile && !chatMsg.isMine(widget.socket.myUid)) {
        _saveFile(chatMsg, showNotification: false);
      }
      
      if (_autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
      }
      widget.onMessagesChanged?.call(chatMessages);
    });
    widget.socket.connectionStatus.listen((connected) {
      if (!mounted) return;
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
    final chatMsg = ChatMessage.fromSocketMessage(msg, widget.socket.myUid);
    if (chatMsg.type == MessageType.chat && 
        !chatMsg.isMine(widget.socket.myUid) &&
        chatMsg.from != null) {
      final users = widget.socket.users;
      final senderName = users != null && chatMsg.from! < users.length
          ? users[chatMsg.from!]['username'] as String? ?? 'Unknown'
          : 'Unknown';
      NotificationService().showMessageNotification(
        senderName,
        chatMsg.content ?? '',
      );
    }
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modeIndex = prefs.getInt('chat_view_mode') ?? 1;
    final markdownEnabled = prefs.getBool('markdown_rendering') ?? true;
    final enterToSend = prefs.getBool('enter_to_send') ?? true;
    final autoScroll = prefs.getBool('auto_scroll') ?? true;
    final autoSaveFiles = prefs.getBool('auto_save_files') ?? false;
    if (!mounted) return;
    setState(() {
      _viewMode = ChatViewMode.values[modeIndex];
      _markdownEnabled = markdownEnabled;
      _enterToSend = enterToSend;
      _autoScroll = autoScroll;
      _autoSaveFiles = autoSaveFiles;
    });

    final colors = await ChatColors.load(isDark);
    if (!mounted) return;
    setState(() {
      _colors = colors;
    });
  }

  Future<void> _loadChatHistoryIfEnabled(SocketMessage serverData) async {
    final prefs = await SharedPreferences.getInstance();
    final loadHistory = prefs.getBool('load_chat_history') ?? false;
    
    if (!loadHistory) return;
    
    final chatHistory = serverData.data['_chat_history'] as List<Map<String, dynamic>>?;
    if (chatHistory == null || chatHistory.isEmpty) return;
    if (mounted) {
      setState(() {
        final historyMessages = chatHistory.map((h) {
          return SocketMessage({
            'type': 'CHAT.RECEIVE',
            'from': h['from'],
            'order': 0,
            'filename': '',
            'content': h['content'],
            'to': h['to'],
            '_is_history': true,
          });
        }).toList();
        final insertIndex = _messages.isEmpty ? 0 : _messages.length;
        _messages.insertAll(insertIndex, historyMessages);
        _messages.insert(insertIndex + historyMessages.length, SocketMessage({
          'type': 'SYSTEM.HISTORY_SEPARATOR',
          'content': '_history_separator_i18n_',
        }));
      });
      
      if (_autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
      }
    }
  }

  void _showEnterHintIfExists(SocketMessage serverDataMsg) {
    final enterHint = widget.socket.serverConfig?['gate']?['enter_hint'] as String?;
    if (enterHint != null && enterHint.isNotEmpty) {
      setState(() {
        _messages.insert(0, SocketMessage({
          'type': 'SYSTEM.ENTER_HINT',
          'content': enterHint,
        }));
      });
    }
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
          icon: Icon(
            Icons.warning_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
            size: 48,
          ),
          title: Text(
            l10n.connectionLost,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.disconnectedFromServer,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            FilledButton(
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
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

  String _buildChatMessageText(ChatMessage msg, AppLocalizations l10n) {
    if (msg.isFile) {
      return '[文件] ${msg.filename}';
    }
    
    return msg.content ?? '';
  }
  
  String _getSenderName(int? fromUid) {
    if (fromUid == null) return 'Unknown';
    final users = widget.socket.users;
    if (users != null && fromUid < users.length && fromUid >= 0) {
      return users[fromUid]['username'] as String? ?? 'Unknown';
    }
    return 'Unknown';
  }

  String _getChatTargetName() {
    if (_chatTarget < 0) return 'Public';
    return _getSenderName(_chatTarget);
  }

  String _translateMessage(ChatMessage msg, AppLocalizations l10n) {
    switch (msg.type) {
      case MessageType.chat:
        if (msg.isBroadcast) {
          final senderName = _getSenderName(msg.from);
          return l10n.broadcastPrefix(senderName) + ' ' + _buildChatMessageText(msg, l10n);
        }
        return _buildChatMessageText(msg, l10n);
      
      case MessageType.gateClientRequest:
        final username = msg.rawData['username'] as String? ?? 'Unknown';
        final uid = msg.rawData['uid'] as int? ?? -1;
        final result = msg.result ?? 'Unknown';
        final resultText = {
          'Accepted': l10n.joinAccepted,
          'Pending review': l10n.joinPending,
          'IP is banned': l10n.joinIpBanned,
          'Room is full': l10n.joinRoomFull,
          'Duplicate usernames': l10n.joinUsernameDuplicate,
          'Username consists of banned words': l10n.joinBannedWords,
        }[result] ?? result;
        return l10n.requestJoinMsg(username, uid.toString(), resultText);
      
      case MessageType.gateRequest:
        final result = msg.rawData['result'] as String? ?? '';
        if (result.isNotEmpty) {
          final resultText = {
            'Accepted': l10n.joinAccepted,
            'Pending review': l10n.joinPending,
            'IP is banned': l10n.joinIpBanned,
            'Room is full': l10n.joinRoomFull,
            'Duplicate usernames': l10n.joinUsernameDuplicate,
            'Username consists of banned words': l10n.joinBannedWords,
          }[result] ?? result;
          return '${l10n.serverResponse}: $resultText';
        }
        return msg.rawData.toString();
      
      case MessageType.gateStatus:
        final uid = msg.uid ?? -1;
        final status = msg.status ?? 'Unknown';
        final targetName = _getSenderName(uid);
        final statusText = {
          'Rejected': l10n.statusRejected,
          'Kicked': l10n.statusKicked,
          'Offline': l10n.statusOffline,
          'Pending': l10n.statusPending,
          'Online': l10n.statusOnline,
          'Admin': l10n.statusAdmin,
          'Root': l10n.statusRoot,
        }[status] ?? status;
        return l10n.statusChangedMsg(targetName, uid.toString(), statusText);
      
      case MessageType.serverConfig:
        final key = msg.rawData['key'] as String? ?? '';
        final value = msg.rawData['value'];
        return l10n.configChangedMsg(key, value.toString());
      
      case MessageType.file:
        return msg.content ?? '';
      
      case MessageType.system:
        final type = msg.rawData['type'] as String?;
        if (type == 'SERVER.DATA') {
          return '';
        } else if (type == 'SYSTEM.ENTER_HINT') {
          return msg.rawData['content'] as String? ?? '';
        } else if (type == 'SYSTEM.HISTORY_SEPARATOR') {
          return l10n.historySeparator;
        } else if (type == 'SERVER.START') {
          final version = msg.rawData['server_version'] as String? ?? 'unknown';
          final time = msg.rawData['time'] as String? ?? '';
          return '${l10n.serverStarted}\n${l10n.serverVersionLabel}: $version\n${l10n.timeLabel}: $time';
        } else if (type == 'SERVER.STOP') {
          final time = msg.rawData['time'] as String? ?? '';
          return '${l10n.serverStopped}\n${l10n.timeLabel}: $time';
        } else if (type == 'GATE.RESPONSE') {
          final result = msg.rawData['result'] as String? ?? '';
          final resultText = {
            'Accepted': l10n.joinAccepted,
            'Pending review': l10n.joinPending,
            'IP is banned': l10n.joinIpBanned,
            'Room is full': l10n.joinRoomFull,
            'Duplicate usernames': l10n.joinUsernameDuplicate,
            'Username consists of banned words': l10n.joinBannedWords,
          }[result] ?? result;
          return '${l10n.serverResponse}: $resultText';
        } else if (type == 'GATE.REVIEW_RESULT') {
          final accepted = msg.rawData['accepted'] as bool? ?? false;
          final operatorData = msg.rawData['operator'] as Map<String, dynamic>?;
          final operatorName = operatorData?['username'] as String? ?? 'Unknown';
          return accepted 
              ? l10n.reviewAccepted(operatorName)
              : l10n.reviewRejected(operatorName);
        }
        return msg.content ?? msg.rawData.toString();
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.socket.sendMessage(text, to: _chatTarget);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _showChatTargetSelector() {
    final l10n = AppLocalizations.of(context);
    final users = widget.socket.users ?? [];
    final myUid = widget.socket.myUid;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectChatTarget),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: Icon(
                  Icons.public,
                  color: _chatTarget == -1 ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(
                  l10n.publicChat,
                  style: TextStyle(
                    fontWeight: _chatTarget == -1 ? FontWeight.bold : null,
                    color: _chatTarget == -1 ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                trailing: _chatTarget == -1 ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _chatTarget = -1);
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              ...users.asMap().entries.where((e) {
                final status = e.value['status'] as String?;
                return e.key != myUid && (status == 'Online' || status == 'Admin' || status == 'Root');
              }).map((e) {
                final uid = e.key;
                final username = e.value['username'] as String? ?? 'Unknown';
                final status = e.value['status'] as String? ?? 'Unknown';
                return ListTile(
                  leading: Icon(
                    Icons.person,
                    color: _chatTarget == uid ? Colors.green : null,
                  ),
                  title: Text(
                    username,
                    style: TextStyle(
                      fontWeight: _chatTarget == uid ? FontWeight.bold : null,
                      color: _chatTarget == uid ? Colors.green : null,
                    ),
                  ),
                  subtitle: Text('UID: $uid - $status'),
                  trailing: _chatTarget == uid ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() => _chatTarget = uid);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes != null) {
      widget.socket.sendFile(file.name, file.bytes!);
    }
  }

  Future<void> _saveFile(ChatMessage msg, {bool showNotification = true}) async {
    if (!msg.isFile || msg.content == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final bytes = base64Decode(msg.content!);
      final filename = msg.filename ?? 'file';
      
      String? downloadPath = prefs.getString('download_path');
      Directory? directory;

      if (downloadPath != null && downloadPath.isNotEmpty) {
        directory = Directory(downloadPath);
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
      } else {
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        }
      }

      if (directory == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.cannotGetDownloadDir)),
          );
        }
        return;
      }

      var filePath = path.join(directory.path, filename);
      var counter = 1;
      while (File(filePath).existsSync()) {
        final extension = path.extension(filename);
        final nameWithoutExt = path.basenameWithoutExtension(filename);
        if (extension.isNotEmpty) {
          filePath = path.join(
            directory.path,
            '$nameWithoutExt($counter)$extension',
          );
        } else {
          filePath = path.join(directory.path, '$filename($counter)');
        }
        counter++;
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted && showNotification) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fileSavedTo(filePath))),
        );
      }
    } catch (e) {
      if (mounted && showNotification) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveFailed('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _colors ?? (isDark ? ChatColors.dark() : ChatColors.light());
    final chatMessages = _messages
        .map((msg) => ChatMessage.fromSocketMessage(msg, widget.socket.myUid))
        .toList();

    return Column(
      children: [
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
              IconButton(
                icon: Icon(
                  _chatTarget == -1 ? Icons.public : Icons.person,
                  color: _chatTarget == -1 ? null : Colors.green,
                ),
                onPressed: _showChatTargetSelector,
                tooltip: _chatTarget == -1 ? l10n.publicChat : '${l10n.privateChat}: ${_getChatTargetName()}',
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: _chatTarget == -1 ? l10n.typeMessage : '${l10n.privateChatTo(_getChatTargetName())}',
                    border: const OutlineInputBorder(),
                    prefixIcon: _chatTarget >= 0 ? Icon(Icons.lock, color: Colors.green, size: 16) : null,
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

        final isSystemMessage = msg.type != MessageType.chat || msg.isBroadcast;
        
        if (isSystemMessage) {
          final translatedContent = _translateMessage(msg, l10n);
          if (translatedContent.isEmpty) {
            return const SizedBox.shrink();
          }
          
          final isBan = translatedContent.contains('封禁') || 
                        translatedContent.contains('ban') ||
                        translatedContent.contains('Kicked');
          final isBroadcast = msg.isBroadcast;
          final bgColor = isBan 
              ? colors.banNotification 
              : (isBroadcast ? colors.banNotification.withOpacity(0.7) : colors.systemMessage);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  translatedContent,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ),
          );
        }

        final isMine = msg.isMine(widget.socket.myUid);
        final senderName = _getSenderName(msg.from);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Align(
            alignment: isMine
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                    child: Text(
                      msg.isPrivate ? '$senderName (${l10n.privateChat})' : senderName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: msg.isPrivate ? FontWeight.bold : null,
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
                    color: msg.isFile
                        ? colors.fileBubble
                        : (msg.isPrivate
                            ? (isMine ? colors.myPrivateBubble : colors.privateBubble)
                            : (isMine
                                ? colors.myMessageBubble
                                : colors.otherMessageBubble)),
                    borderRadius: BorderRadius.circular(18),
                    border: msg.isFile
                        ? Border.all(color: Colors.amber.shade700, width: 2)
                        : (msg.isPrivate
                            ? Border.all(color: isMine ? Colors.purple : Colors.green, width: 2)
                            : null),
                  ),
                  child: msg.isFile
                      ? InkWell(
                          onTap: () => _saveFile(msg),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder,
                                color: Colors.amber.shade700,
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      msg.filename ?? 'file',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.clickToSaveFile,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.amber.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : MessageContent(
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

        final isSystemMessage = msg.type != MessageType.chat || msg.isBroadcast;

        if (isSystemMessage) {
          final translatedContent = _translateMessage(msg, l10n);
          if (translatedContent.isEmpty) {
            return const SizedBox.shrink();
          }
        }

        final isMine = msg.isMine(widget.socket.myUid);
        Color? bgColor;
        if (isSystemMessage) {
          final translatedContent = _translateMessage(msg, l10n);
          final isBan = translatedContent.contains('封禁') || 
                        translatedContent.contains('ban') ||
                        translatedContent.contains('Kicked');
          final isBroadcast = msg.isBroadcast;
          bgColor = isBan 
              ? colors.banNotification 
              : (isBroadcast ? colors.banNotification.withOpacity(0.7) : colors.systemMessage);
        } else if (msg.isFile) {
          bgColor = colors.fileBubble;
        } else if (msg.isPrivate) {
          bgColor = isMine ? colors.myPrivateBubble : colors.privateBubble;
        } else {
          bgColor = isMine ? colors.myMessageBubble : colors.otherMessageBubble;
        }

        return InkWell(
          onTap: msg.isFile ? () => _saveFile(msg) : null,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: msg.isFile
                  ? Border.all(color: Colors.amber.shade700, width: 2)
                  : (msg.isPrivate
                      ? Border.all(color: isMine ? Colors.purple : Colors.green, width: 2)
                      : null),
            ),
            child: msg.isFile
                ? Row(
                    children: [
                      Icon(
                        Icons.folder,
                        color: Colors.amber.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.filename ?? 'file',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            Text(
                              '点击保存文件',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : MessageContent(
                    text: msg.type == MessageType.chat
                        ? _buildChatMessageText(msg, l10n)
                        : _translateMessage(msg, l10n),
                    enableMarkdown: _markdownEnabled,
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
          ),
        );
      },
    );
  }
}
