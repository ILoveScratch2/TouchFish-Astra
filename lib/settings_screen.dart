import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'app_localizations.dart';
import 'constants.dart';
import 'models/chat_colors.dart';
import 'chat_screen.dart';
import 'socket_service.dart';
import 'boss_key_service.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode currentTheme;
  final Locale currentLocale;
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final ValueNotifier<int>? settingsChangeNotifier;
  final SocketService? socketService;

  const SettingsScreen({
    super.key,
    required this.currentTheme,
    required this.currentLocale,
    required this.onThemeToggle,
    required this.onLanguageChange,
    this.settingsChangeNotifier,
    this.socketService,
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
  bool _enableNotifications = false;
  bool _bossKeyEnabled = false;
  String _bossKeyShortcut = 'Ctrl + `';
  final _bossKeyService = BossKeyService();

  @override
  void initState() {
    super.initState();
    _loadColors();
    _loadSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBossKeyShortcut() async {
    final keyCode = await _bossKeyService.getKeyCode();
    final modifiers = await _bossKeyService.getModifiers();
    setState(() {
      _bossKeyShortcut = _bossKeyService.formatShortcut(modifiers, keyCode);
    });
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
      _autoSaveFiles = prefs.getBool('auto_save_files') ?? true;
      _downloadPath = prefs.getString('download_path') ?? defaultPath;
      _markdownRendering = prefs.getBool('markdown_rendering') ?? true;
      _enterToSend = prefs.getBool('enter_to_send') ?? true;
      _enableNotifications = prefs.getBool('enable_notifications') ?? false;
      _bossKeyEnabled = prefs.getBool('boss_key_enabled') ?? false;
    });
    
    await _loadBossKeyShortcut();
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.appName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.version} ${AppConstants.version}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                isZh ? AppConstants.descriptionZh : AppConstants.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(AppConstants.githubUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: Text(
                  AppConstants.githubUrl,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'by ${AppConstants.author}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.license,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                isZh ? AppConstants.fontLicenseZh : AppConstants.fontLicenseEn,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
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

  Future<void> _showShortcutDialog() async {
    final l10n = AppLocalizations.of(context);
    String? recordedKey;
    List<String> recordedModifiers = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.bossKeyChange),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.bossKeyRecording),
              const SizedBox(height: 16),
              Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event.runtimeType.toString().contains('KeyDownEvent')) {
                    final key = event.physicalKey;
                    final logicalKey = event.logicalKey;
                    final mods = <String>[];
                    
                    if (logicalKey.keyId >= LogicalKeyboardKey.controlLeft.keyId &&
                        logicalKey.keyId <= LogicalKeyboardKey.controlRight.keyId) {
                      return KeyEventResult.handled;
                    }
                    if (logicalKey.keyId >= LogicalKeyboardKey.altLeft.keyId &&
                        logicalKey.keyId <= LogicalKeyboardKey.altRight.keyId) {
                      return KeyEventResult.handled;
                    }
                    if (logicalKey.keyId >= LogicalKeyboardKey.shiftLeft.keyId &&
                        logicalKey.keyId <= LogicalKeyboardKey.shiftRight.keyId) {
                      return KeyEventResult.handled;
                    }
                    if (logicalKey.keyId >= LogicalKeyboardKey.metaLeft.keyId &&
                        logicalKey.keyId <= LogicalKeyboardKey.metaRight.keyId) {
                      return KeyEventResult.handled;
                    }

                    if (HardwareKeyboard.instance.logicalKeysPressed.any((k) => 
                        k.keyId >= LogicalKeyboardKey.controlLeft.keyId &&
                        k.keyId <= LogicalKeyboardKey.controlRight.keyId)) {
                      mods.add('control');
                    }
                    if (HardwareKeyboard.instance.logicalKeysPressed.any((k) => 
                        k.keyId >= LogicalKeyboardKey.altLeft.keyId &&
                        k.keyId <= LogicalKeyboardKey.altRight.keyId)) {
                      mods.add('alt');
                    }
                    if (HardwareKeyboard.instance.logicalKeysPressed.any((k) => 
                        k.keyId >= LogicalKeyboardKey.shiftLeft.keyId &&
                        k.keyId <= LogicalKeyboardKey.shiftRight.keyId)) {
                      mods.add('shift');
                    }
                    if (HardwareKeyboard.instance.logicalKeysPressed.any((k) => 
                        k.keyId >= LogicalKeyboardKey.metaLeft.keyId &&
                        k.keyId <= LogicalKeyboardKey.metaRight.keyId)) {
                      mods.add('meta');
                    }

                    final keyLabel = key.debugName ?? '';
                    if (keyLabel.isNotEmpty) {
                      if (mods.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.bossKeyInvalid)),
                        );
                        return KeyEventResult.handled;
                      }

                      setState(() {
                        recordedKey = keyLabel;
                        recordedModifiers = mods;
                      });
                    }
                  }
                  return KeyEventResult.handled;
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recordedKey != null
                        ? _bossKeyService.formatShortcut(recordedModifiers, recordedKey!)
                        : '...',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: recordedKey != null
                  ? () async {
                      await _bossKeyService.saveShortcut(recordedKey!, recordedModifiers);
                      await _loadBossKeyShortcut();
                      await _bossKeyService.unregister();
                      await _bossKeyService.register();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  : null,
              child: Text(l10n.ok),
            ),
          ],
        ),
      ),
    );
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
              if (!kIsWeb && Platform.isWindows) ...[
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off),
                  title: Text(l10n.bossKey),
                  subtitle: Text(l10n.bossKeyHint),
                  value: _bossKeyEnabled,
                  onChanged: (value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('boss_key_enabled', value);
                    setState(() {
                      _bossKeyEnabled = value;
                    });
                    if (value) {
                      await _bossKeyService.register();
                    } else {
                      await _bossKeyService.unregister();
                    }
                  },
                ),
                if (_bossKeyEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.keyboard),
                    title: Text(l10n.bossKeyShortcut),
                    subtitle: Text('${l10n.bossKeyCurrent}: $_bossKeyShortcut'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: l10n.bossKeyReset,
                          onPressed: () async {
                            await _bossKeyService.resetToDefault();
                            await _loadBossKeyShortcut();
                            await _bossKeyService.unregister();
                            await _bossKeyService.register();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: l10n.bossKeyChange,
                          onPressed: () => _showShortcutDialog(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (kIsWeb || !Platform.isWindows) ...[
                const Divider(height: 1),
                ListTile(
                  enabled: false,
                  leading: const Icon(Icons.visibility_off),
                  title: Text(l10n.bossKey),
                  subtitle: Text(l10n.bossKeyWindowsOnly),
                  trailing: const Switch(
                    value: false,
                    onChanged: null,
                  ),
                ),
              ],
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
