import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'socket_service.dart';

class MainNavigation extends StatefulWidget {
  final SocketService socket;
  final String username;
  final ThemeMode currentTheme;
  final VoidCallback onThemeToggle;

  const MainNavigation({
    super.key,
    required this.socket,
    required this.username,
    required this.currentTheme,
    required this.onThemeToggle,
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
          onThemeToggle: widget.onThemeToggle,
        ),
      _ => const SizedBox(),
    };
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.chat_outlined),
          selectedIcon: Icon(Icons.chat),
          label: Text('Chat'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }

  Drawer _buildDrawer() {
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
                  'TouchFishAstra',
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
            title: const Text('Chat'),
            selected: _currentIndex == 0,
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
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
          _currentIndex == 0 ? 'Chat - ${widget.username}' : 'Settings',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: _buildDrawer(),
      body: _buildContent(),
    );
  }
}
