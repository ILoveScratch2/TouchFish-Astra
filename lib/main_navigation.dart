import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'chat_screen.dart';
import 'admin_screen.dart';
import 'settings_screen.dart';
import 'socket_service.dart';
import 'app_localizations.dart';
import 'constants.dart';

enum NavigationTab { chat, admin, settings }

class MainNavigation extends StatefulWidget {
  final SocketService socket;
  final String username;
  final ThemeMode currentTheme;
  final Locale currentLocale;
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;

  const MainNavigation({
    super.key,
    required this.socket,
    required this.username,
    required this.currentTheme,
    required this.currentLocale,
    required this.onThemeToggle,
    required this.onLanguageChange,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  var _currentTab = NavigationTab.chat;
  late final AdminScreen _adminScreen;
  late final ChatScreen _chatScreen;
  final _settingsChangeNotifier = ValueNotifier<int>(0);
  final _chatMessages = <dynamic>[];

  @override
  void initState() {
    super.initState();
    
    _chatScreen = ChatScreen(
      socket: widget.socket,
      username: widget.username,
      settingsChangeNotifier: _settingsChangeNotifier,
      onMessagesChanged: (messages) {
        _chatMessages.clear();
        _chatMessages.addAll(messages);
      },
    );
    
    _adminScreen = AdminScreen(socket: widget.socket);
  }

  @override
  void dispose() {
    _settingsChangeNotifier.dispose();
    super.dispose();
  }
  
  void _showServerInfo() {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) {
        final serverVersion = widget.socket.serverConfig?['server_version'] ?? 'unknown';
        final serverConfig = widget.socket.serverConfig;
        final maxConnections = serverConfig?['general']?['max_connections'] ?? 0;
        final users = widget.socket.users ?? [];
        final onlineCount = users.where((u) {
          final status = u['status'] as String?;
          return status == 'Online' || status == 'Admin' || status == 'Root';
        }).length;
          
          return AlertDialog(
            title: Text(l10n.serverInfo),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.serverVersionLabel}: $serverVersion'),
                  const SizedBox(height: 8),
                  Text('${l10n.myUid}: ${widget.socket.myUid}'),
                  const SizedBox(height: 8),
                  Text('${l10n.translate('online_users')}: $onlineCount / $maxConnections'),
                  const Divider(),
                  Text(l10n.userList, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: users.isEmpty
                        ? const Text('No users')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final username = user['username'] ?? 'Unknown';
                              final uid = user['uid'] ?? -1;
                              final status = user['status'] ?? 'Unknown';
                              return ListTile(
                                dense: true,
                                title: Text(username),
                                subtitle: Text('${l10n.uid}: $uid - ${l10n.status}: $status'),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          );
      },
    );
  }

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  Widget _buildContent() {
    return IndexedStack(
      index: _currentTab.index,
      children: [
        _chatScreen,
        _adminScreen,
        SettingsScreen(
          currentTheme: widget.currentTheme,
          currentLocale: widget.currentLocale,
          onThemeToggle: widget.onThemeToggle,
          onLanguageChange: widget.onLanguageChange,
          settingsChangeNotifier: _settingsChangeNotifier,
          socketService: widget.socket,
          chatMessages: _chatMessages,
        ),
      ],
    );
  }

  Widget _buildNavigationRail() {
    final l10n = AppLocalizations.of(context);
    final mainTabs = [NavigationTab.chat, NavigationTab.admin];
    final selectedMainIndex = mainTabs.contains(_currentTab) 
        ? mainTabs.indexOf(_currentTab) 
        : 0;
    
    return NavigationRail(
      selectedIndex: selectedMainIndex,
      onDestinationSelected: (i) => setState(() => _currentTab = mainTabs[i]),
      labelType: NavigationRailLabelType.all,
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 24),
                  onPressed: _showServerInfo,
                  tooltip: l10n.serverInfo,
                ),
                Text(
                  l10n.serverInfo,
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                IconButton(
                  icon: Icon(
                    _currentTab == NavigationTab.settings
                        ? Icons.settings
                        : Icons.settings_outlined,
                    size: 24,
                  ),
                  onPressed: () => setState(() => _currentTab = NavigationTab.settings),
                  tooltip: l10n.settings,
                  isSelected: _currentTab == NavigationTab.settings,
                ),
                Text(
                  l10n.settings,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _currentTab == NavigationTab.settings
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.chat_outlined),
          selectedIcon: const Icon(Icons.chat),
          label: Text(l10n.chat),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: const Icon(Icons.admin_panel_settings),
          label: Text(l10n.admin),
        ),
      ],
    );
  }

  Drawer _buildDrawer() {
    final l10n = AppLocalizations.of(context);
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.username,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: Text(l10n.chat),
            selected: _currentTab == NavigationTab.chat,
            onTap: () {
              setState(() => _currentTab = NavigationTab.chat);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: Text(l10n.admin),
            selected: _currentTab == NavigationTab.admin,
            onTap: () {
              setState(() => _currentTab = NavigationTab.admin);
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.serverInfo),
            onTap: () {
              Navigator.pop(context);
              _showServerInfo();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settings),
            selected: _currentTab == NavigationTab.settings,
            onTap: () {
              setState(() => _currentTab = NavigationTab.settings);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildNavigationRail(),
            const VerticalDivider(width: 1),
            Expanded(child: _buildContent()),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (_currentTab) {
            NavigationTab.chat => '${l10n.chat} - ${widget.username}',
            NavigationTab.admin => l10n.admin,
            NavigationTab.settings => l10n.settings,
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _currentTab == NavigationTab.chat
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'server_info') {
                      _showServerInfo();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'server_info',
                      child: Text(l10n.serverInfo),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      drawer: _buildDrawer(),
      body: _buildContent(),
    );
  }
}
