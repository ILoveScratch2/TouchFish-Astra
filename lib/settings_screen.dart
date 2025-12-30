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

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  ChatColors? _colors;
  bool _autoSaveFiles = true;
  String _downloadPath = '';
  bool _markdownRendering = true;
  bool _enterToSend = true;
  bool _autoScroll = true;
  bool _enableNotifications = false;
  bool _loadChatHistory = false;
  
  // 彩蛋 （被你发现了！）
  int _easterEggTapCount = 0;
  DateTime? _lastTapTime;
  AnimationController? _shakeController;
  AnimationController? _scaleController;
  Animation<double>? _shakeAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadColors();
    _loadSettings();
    _loadEasterEggCount();
    _initAnimations();
  }
  
  void _initAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController!,
        curve: Curves.elasticIn,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _scaleController!,
        curve: Curves.easeOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _shakeController?.dispose();
    _scaleController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadEasterEggCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _easterEggTapCount = prefs.getInt('easter_egg_tap_count') ?? 0;
    });
  }
  
  Future<void> _saveEasterEggCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('easter_egg_tap_count', _easterEggTapCount);
  }
  
  void _handleEasterEggTap(BuildContext context) {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 300) {
      return;
    }
    _lastTapTime = now;
    
    setState(() {
      _easterEggTapCount++;
    });
    _saveEasterEggCount();
    _shakeController?.forward(from: 0);
    _scaleController?.forward(from: 0).then((_) {
      _scaleController?.reverse();
    });
    _showEasterEggSnackBar(context);
  }
  
  void _showEasterEggSnackBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String quote = _getEasterEggQuote(l10n);
    String? achievement = _getEasterEggAchievement(l10n);
    
    ScaffoldMessenger.of(context).clearSnackBars();
    
    if (achievement != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.translate('easter_egg_tap_count', [_easterEggTapCount.toString()]),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.purple.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quote),
          backgroundColor: Colors.blue.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
  
  String _getEasterEggQuote(AppLocalizations l10n) {
    final quotes = [
      'easter_egg_quote_1',
      'easter_egg_quote_2',
      'easter_egg_quote_3',
      'easter_egg_quote_4',
      'easter_egg_quote_5',
      'easter_egg_quote_6',
      'easter_egg_quote_7',
      'easter_egg_quote_8',
      'easter_egg_quote_9',
      'easter_egg_quote_10',
    ];
    
    final index = (_easterEggTapCount - 1) % quotes.length;
    return l10n.translate(quotes[index]);
  }
  
  String? _getEasterEggAchievement(AppLocalizations l10n) {
    final milestones = [
      (5, 'easter_egg_level_1'),
      (10, 'easter_egg_level_2'),
      (20, 'easter_egg_level_3'),
      (50, 'easter_egg_level_4'),
      (100, 'easter_egg_level_5'),
      (200, 'easter_egg_level_6'),
      (500, 'easter_egg_level_7'),
    ];
    
    for (final (count, levelKey) in milestones) {
      if (_easterEggTapCount == count) {
        final levelName = l10n.translate(levelKey);
        return l10n.translate('easter_egg_achievement', [levelName]);
      }
    }
    
    return null;
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
                    GestureDetector(
                      onTap: () => _handleEasterEggTap(context),
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_shakeController, _scaleController]),
                        builder: (context, child) {
                          final shakeValue = _shakeAnimation?.value ?? 0;
                          final scaleValue = _scaleAnimation?.value ?? 1.0;
                          return Transform.translate(
                            offset: Offset((shakeValue * ((_easterEggTapCount % 2 == 0) ? 1 : -1)), 0),
                            child: Transform.scale(
                              scale: scaleValue,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
