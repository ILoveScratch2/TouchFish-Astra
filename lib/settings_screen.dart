import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'app_localizations.dart';
import 'constants.dart';
import 'models/chat_colors.dart';
import 'models/chat_message.dart';
import 'chat_screen.dart';
import 'socket_service.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode currentTheme;
  final Locale currentLocale;
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final ValueNotifier<int>? settingsChangeNotifier;
  final SocketService? socketService;
  final List<dynamic>? chatMessages;

  const SettingsScreen({
    super.key,
    required this.currentTheme,
    required this.currentLocale,
    required this.onThemeToggle,
    required this.onLanguageChange,
    this.settingsChangeNotifier,
    this.socketService,
    this.chatMessages,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ChatColors? _colors;
  ChatViewMode _viewMode = ChatViewMode.bubble;
  bool _autoSaveFiles = true;
  String _downloadPath = '';
  bool _markdownRendering = true;
  bool _enterToSend = true;
  bool _autoScroll = true;
  bool _enableNotifications = false;
  bool _loadChatHistory = false;

  @override
  void initState() {
    super.initState();
    _loadColors();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    String defaultPath = '';
    try {
      if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        defaultPath = dir?.path ?? '';
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final dir = await getDownloadsDirectory();
        defaultPath = dir?.path ?? '';
      }
    } catch (_) {
      defaultPath = '';
    }

    setState(() {
      _viewMode = ChatViewMode.values[prefs.getInt('chat_view_mode') ?? 1];
      _autoSaveFiles = prefs.getBool('auto_save_files') ?? false;
      _downloadPath = prefs.getString('download_path') ?? defaultPath;
      _markdownRendering = prefs.getBool('markdown_rendering') ?? true;
      _enterToSend = prefs.getBool('enter_to_send') ?? true;
      _autoScroll = prefs.getBool('auto_scroll') ?? true;
      _enableNotifications = prefs.getBool('enable_notifications') ?? false;
      _loadChatHistory = prefs.getBool('load_chat_history') ?? false;
    });
  }

  Future<void> _pickDownloadPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('download_path', result);
      setState(() {
        _downloadPath = result;
      });
    }
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTheme != widget.currentTheme) {
      _loadColors();
    }
  }

  Future<void> _loadColors() async {
    final isDark = widget.currentTheme == ThemeMode.dark;
    final colors = await ChatColors.load(isDark);
    setState(() {
      _colors = colors;
    });
  }

  Future<void> _pickColor(
    BuildContext context,
    String title,
    Color currentColor,
    Function(Color) onColorChanged,
  ) async {
    final l10n = AppLocalizations.of(context);
    Color? selectedColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...Colors.primaries
                  .map((color) {
                    return [
                      _colorOption(context, color[100]!, selectedColor, (c) {
                        selectedColor = c;
                        onColorChanged(c);
                        Navigator.pop(context);
                      }),
                      _colorOption(context, color[300]!, selectedColor, (c) {
                        selectedColor = c;
                        onColorChanged(c);
                        Navigator.pop(context);
                      }),
                      _colorOption(context, color[700]!, selectedColor, (c) {
                        selectedColor = c;
                        onColorChanged(c);
                        Navigator.pop(context);
                      }),
                      _colorOption(context, color[900]!, selectedColor, (c) {
                        selectedColor = c;
                        onColorChanged(c);
                        Navigator.pop(context);
                      }),
                    ];
                  })
                  .expand((e) => e),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _colorOption(
    BuildContext context,
    Color color,
    Color? selected,
    Function(Color) onTap,
  ) {
    return InkWell(
      onTap: () => onTap(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected == color
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 600 ? 500.0 : size.width * 0.9;
    final maxHeight = size.height * 0.8;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.version} ${AppConstants.version}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isZh ? AppConstants.descriptionZh : AppConstants.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),

                        InkWell(
                          onTap: () async {
                            final uri = Uri.parse(AppConstants.githubUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.code,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppConstants.githubUrl,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        Text(
                          'by ${AppConstants.author}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppConstants.license,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        
                        Text(
                          isZh ? AppConstants.fontLicenseZh : AppConstants.fontLicenseEn,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 关闭按钮
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.ok),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDisconnect(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDisconnect),
        content: Text(l10n.confirmDisconnectMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.disconnect),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.socketService != null) {
      widget.socketService!.disconnect();
    }
  }

  Future<void> _exportChatHistory(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    if (widget.chatMessages == null || widget.chatMessages!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noMessagesToExport)),
      );
      return;
    }

    try {
      final buffer = StringBuffer();
      final users = widget.socketService?.users;
      
      for (final msg in widget.chatMessages!) {
        final timestamp = msg.timestamp;
        final timeStr = '${timestamp.year.toString().padLeft(4, '0')}/'
            '${timestamp.month.toString().padLeft(2, '0')}/'
            '${timestamp.day.toString().padLeft(2, '0')} '
            '${timestamp.hour.toString().padLeft(2, '0')}:'
            '${timestamp.minute.toString().padLeft(2, '0')}:'
            '${timestamp.second.toString().padLeft(2, '0')}';

        final msgType = msg.type;
        
        if (msgType == MessageType.chat) {
          String username = msg.username ?? 'Unknown';
          if (username == 'Unknown' && msg.from != null && users != null && msg.from! < users.length) {
            username = users[msg.from!]['username'] as String? ?? 'Unknown';
          }
          
          if (msg.isFile) {
            buffer.writeln('[$timeStr] $username: [FILE] ${msg.filename}');
          } else {
            buffer.writeln('[$timeStr] $username: ${msg.content ?? ""}');
          }
        } else if (msgType == MessageType.gateClientRequest) {
          final username = msg.username ?? 'Unknown';
          final uid = msg.uid ?? -1;
          final result = msg.result ?? 'Unknown';
          buffer.writeln('[$timeStr] [${l10n.translate('join_request')}] $username (UID: $uid) - $result');
        } else if (msgType == MessageType.gateStatus) {
          final uid = msg.uid ?? -1;
          final status = msg.status ?? 'Unknown';
          buffer.writeln('[$timeStr] [${l10n.translate('status_change')}] UID $uid -> $status');
        } else if (msgType == MessageType.serverConfig) {
          final key = msg.rawData['key'] as String? ?? 'unknown';
          final value = msg.rawData['value'];
          buffer.writeln('[$timeStr] [${l10n.translate('config_change')}] $key = $value');
        } else {
          final content = msg.content ?? msg.rawData.toString();
          buffer.writeln('[$timeStr] [${l10n.translate('system')}] $content');
        }
      }

      final content = buffer.toString();
      final fileName = 'touchfish_chat_${DateTime.now().millisecondsSinceEpoch}.txt';
      if (Platform.isAndroid || Platform.isIOS) {
        final bytes = utf8.encode(content);
        final result = await FilePicker.platform.saveFile(
          dialogTitle: l10n.exportChatHistory,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['txt'],
          bytes: bytes,
        );

        if (result == null) return;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportedTo(result)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: l10n.exportChatHistory,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['txt'],
        );

        if (result == null) return;

        final file = File(result);
        await file.writeAsString(content, encoding: utf8);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportedTo(result)),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: l10n.openFile,
              onPressed: () async {
                try {
                  final uri = Uri.file(result);
                  await launchUrl(uri);
                } catch (_) {}
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.exportFailed}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.currentTheme == ThemeMode.dark;
    final colors = _colors ?? (isDark ? ChatColors.dark() : ChatColors.light());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.settings,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: Icon(
              widget.currentTheme == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: Text(l10n.theme),
            subtitle: Text(
              widget.currentTheme == ThemeMode.dark
                  ? l10n.themeDark
                  : l10n.themeLight,
            ),
            trailing: Switch(
              value: widget.currentTheme == ThemeMode.dark,
              onChanged: (_) => widget.onThemeToggle(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(
              widget.currentLocale.languageCode == 'zh' ? '简体中文' : 'English',
            ),
            trailing: DropdownButton<String>(
              value: widget.currentLocale.languageCode,
              items: const [
                DropdownMenuItem(value: 'zh', child: Text('简体中文')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.onLanguageChange(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.socketService != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.link_off),
              title: Text(l10n.disconnectFromServer),
              enabled: widget.socketService!.isConnected,
              onTap: widget.socketService!.isConnected
                  ? () => _handleDisconnect(context)
                  : null,
              trailing: widget.socketService!.isConnected
                  ? const Icon(Icons.chevron_right)
                  : null,
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.file_download),
            title: Text(l10n.exportChatHistory),
            subtitle: Text(l10n.exportChatHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportChatHistory(context),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.chatSettings,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.view_module),
                title: Text(l10n.chatViewMode),
                subtitle: Text(
                  _viewMode == ChatViewMode.bubble ? l10n.bubbleMode : l10n.listMode,
                ),
                trailing: SegmentedButton<ChatViewMode>(
                  segments: [
                    ButtonSegment(
                      value: ChatViewMode.bubble,
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: Text(l10n.bubble),
                    ),
                    ButtonSegment(
                      value: ChatViewMode.list,
                      icon: const Icon(Icons.list, size: 16),
                      label: Text(l10n.list),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (Set<ChatViewMode> selected) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('chat_view_mode', selected.first.index);
                    setState(() {
                      _viewMode = selected.first;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.save_alt),
                title: Text(l10n.autoSaveFiles),
                subtitle: Text(l10n.autoSaveHint),
                value: _autoSaveFiles,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('auto_save_files', value);
                  setState(() {
                    _autoSaveFiles = value;
                  });
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.text_format),
                title: Text(l10n.markdownRendering),
                subtitle: Text(l10n.markdownHint),
                value: _markdownRendering,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('markdown_rendering', value);
                  setState(() {
                    _markdownRendering = value;
                  });
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.keyboard_return),
                title: Text(l10n.enterToSend),
                subtitle: Text(l10n.enterToSendHint),
                value: _enterToSend,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('enter_to_send', value);
                  setState(() {
                    _enterToSend = value;
                  });
                  widget.settingsChangeNotifier?.value++;
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.arrow_downward),
                title: Text(l10n.autoScroll),
                subtitle: Text(l10n.autoScrollHint),
                value: _autoScroll,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('auto_scroll', value);
                  setState(() {
                    _autoScroll = value;
                  });
                  widget.settingsChangeNotifier?.value++;
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: Text(l10n.enableNotifications),
                subtitle: Text(l10n.notificationsHint),
                value: _enableNotifications,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('enable_notifications', value);
                  setState(() {
                    _enableNotifications = value;
                  });
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.history),
                title: Text(l10n.loadChatHistory),
                subtitle: Text(l10n.loadChatHistoryHint),
                value: _loadChatHistory,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('load_chat_history', value);
                  setState(() {
                    _loadChatHistory = value;
                  });
                  widget.settingsChangeNotifier?.value++;
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.folder),
                title: Text(l10n.downloadPath),
                subtitle: Text(
                  _downloadPath.isEmpty ? l10n.defaultFolder : _downloadPath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_downloadPath.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: l10n.resetDefault,
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('download_path');
                          await _loadSettings();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      tooltip: l10n.selectFolder,
                      onPressed: _pickDownloadPath,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.colorSettings,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.chat_bubble),
                title: Text(l10n.myBubbleColor),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.myMessageBubble,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                onTap: () async {
                  await _pickColor(
                    context,
                    l10n.pickMyColor,
                    colors.myMessageBubble,
                    (color) async {
                      final newColors = colors.copyWith(myMessageBubble: color);
                      await newColors.save();
                      await _loadColors();
                    },
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(l10n.otherBubbleColor),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.otherMessageBubble,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                onTap: () async {
                  await _pickColor(
                    context,
                    l10n.pickOtherColor,
                    colors.otherMessageBubble,
                    (color) async {
                      final newColors = colors.copyWith(
                        otherMessageBubble: color,
                      );
                      await newColors.save();
                      await _loadColors();
                    },
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(l10n.systemMsgColor),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.systemMessage,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                onTap: () async {
                  await _pickColor(
                    context,
                    l10n.pickSystemColor,
                    colors.systemMessage,
                    (color) async {
                    final newColors = colors.copyWith(systemMessage: color);
                    await newColors.save();
                    await _loadColors();
                  });
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(l10n.banColor),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.banNotification,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                onTap: () async {
                  await _pickColor(
                    context,
                    l10n.pickBanColor,
                    colors.banNotification,
                    (color) async {
                      final newColors = colors.copyWith(banNotification: color);
                      await newColors.save();
                      await _loadColors();
                    },
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.green),
                title: Text(l10n.otherPrivateColor),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.privateBubble,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                onTap: () async {
                  await _pickColor(
                    context,
                    l10n.pickOtherPrivateColor,
                    colors.privateBubble,
                    (color) async {
                      final newColors = colors.copyWith(privateBubble: color);
                      await newColors.save();
                      await _loadColors();
                    },
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.purple),
                title: Text(l10n.myPrivateColor),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.myPrivateBubble,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                onTap: () async {
                  await _pickColor(
                    context,
                    l10n.pickMyPrivateColor,
                    colors.myPrivateBubble,
                    (color) async {
                      final newColors = colors.copyWith(myPrivateBubble: color);
                      await newColors.save();
                      await _loadColors();
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            subtitle: Text('${AppConstants.version} by ${AppConstants.author}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context),
          ),
        ),
      ],
    );
  }
}
