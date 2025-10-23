import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode currentTheme;
  final VoidCallback onThemeToggle;

  const SettingsScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: Icon(
              currentTheme == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: const Text('Theme'),
            subtitle: Text(
              currentTheme == ThemeMode.dark ? 'Dark' : 'Light',
            ),
            trailing: Switch(
              value: currentTheme == ThemeMode.dark,
              onChanged: (_) => onThemeToggle(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('v0.1.0 by ILoveScratch2'),
          ),
        ),
      ],
    );
  }
}
