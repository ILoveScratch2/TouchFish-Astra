import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'socket_service.dart';
import 'app_localizations.dart';
import 'constants.dart';

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
  var _currentIndex = 0;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  Widget _buildContent() {
    return switch (_currentIndex) {
      0 => ChatScreen(socket: widget.socket, username: widget.username),
      1 => SettingsScreen(
          currentTheme: widget.currentTheme,
          currentLocale: widget.currentLocale,
          onThemeToggle: widget.onThemeToggle,
          onLanguageChange: widget.onLanguageChange,
        ),
      _ => const SizedBox(),
    };
  }

  Widget _buildNavigationRail() {
    final l10n = AppLocalizations.of(context);
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      labelType: NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.chat_outlined),
          selectedIcon: const Icon(Icons.chat),
          label: Text(l10n.chat),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(l10n.settings),
        ),
      ],
    );
  }

  Drawer _buildDrawer() {
    final l10n = AppLocalizations.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
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
          ListTile(
            leading: const Icon(Icons.chat),
            title: Text(l10n.chat),
            selected: _currentIndex == 0,
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settings),
            selected: _currentIndex == 1,
            onTap: () {
              setState(() => _currentIndex = 1);
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
          _currentIndex == 0 ? '${l10n.chat} - ${widget.username}' : l10n.settings,
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: _buildDrawer(),
      body: _buildContent(),
    );
  }
}
