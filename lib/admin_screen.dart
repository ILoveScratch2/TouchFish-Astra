import 'dart:async';
import 'package:flutter/material.dart';
import 'socket_service.dart';
import 'app_localizations.dart';

class AdminScreen extends StatefulWidget {
  final SocketService socket;

  const AdminScreen({super.key, required this.socket});

  @override
  AdminScreenState createState() => AdminScreenState();
}

class AdminScreenState extends State<AdminScreen> {
  StreamSubscription<SocketMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.socket.messages.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool get _isAdmin {
    final users = widget.socket.users;
    final myUid = widget.socket.myUid;
    if (users == null || myUid == null || myUid >= users.length) return false;
    final status = users[myUid]['status'] as String?;
    return status == 'Admin' || status == 'Root';
  }

  List<Map<String, dynamic>> get _pendingUsers {
    final users = widget.socket.users ?? [];
    return users
        .asMap()
        .entries
        .where((e) => e.value['status'] == 'Pending')
        .map((e) {
          final user = Map<String, dynamic>.from(e.value);
          user['uid'] = e.key;
          return user;
        })
        .toList();
  }

  List<Map<String, dynamic>> get _onlineUsers {
    final users = widget.socket.users ?? [];
    final myUid = widget.socket.myUid;
    return users
        .asMap()
        .entries
        .where((e) {
          final status = e.value['status'] as String?;
          return e.key != myUid && (status == 'Online' || status == 'Admin' || status == 'Root');
        })
        .map((e) {
          final user = Map<String, dynamic>.from(e.value);
          user['uid'] = e.key;
          return user;
        })
        .toList();
  }

  void _acceptUser(int uid) {
    widget.socket.acceptUser(uid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Accepted user UID: $uid')),
    );
  }

  void _rejectUser(int uid) {
    widget.socket.rejectUser(uid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rejected user UID: $uid')),
    );
  }

  void _kickUser(int uid) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmKickTitle),
        content: Text(l10n.confirmKickMessage('$uid')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.socket.kickUser(uid);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.kickedUser('$uid'))),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.kick),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.translate('admin_broadcast')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.translate('admin_broadcast_hint'),
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final content = controller.text.trim();
                if (content.isNotEmpty) {
                  widget.socket.sendBroadcast(content);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.translate('admin_broadcast_sent'))),
                  );
                }
              },
              child: Text(l10n.translate('send')),
            ),
          ],
        );
      },
    );
  }

  void _showConfigDialog() {
    final valueController = TextEditingController();
    String selectedKey = 'gate.enter_check';
    
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            final currentValue = _getConfigValue(selectedKey);
            if (valueController.text.isEmpty && currentValue != null) {
              valueController.text = currentValue.toString();
            }
            
            return AlertDialog(
              title: Text(l10n.translate('admin_config')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedKey,
                    decoration: InputDecoration(
                      labelText: l10n.translate('admin_config_key'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      'gate.enter_check',
                      'message.allow_private',
                      'message.max_length',
                      'file.allow_any',
                      'file.allow_private',
                      'file.max_size',
                    ].map((key) => DropdownMenuItem(value: key, child: Text(key))).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedKey = value;
                          final newValue = _getConfigValue(value);
                          valueController.text = newValue?.toString() ?? '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                      labelText: l10n.translate('admin_config_value'),
                      hintText: _getConfigHint(selectedKey),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.translate('cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final value = valueController.text.trim();
                    if (value.isNotEmpty) {
                      dynamic parsedValue = value;
                      if (value == 'true' || value == 'false') {
                        parsedValue = value == 'true';
                      } else if (int.tryParse(value) != null) {
                        parsedValue = int.parse(value);
                      }
                      widget.socket.updateConfig(selectedKey, parsedValue);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.translate('admin_config_updated'))),
                      );
                    }
                  },
                  child: Text(l10n.translate('update')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBanDialog() {
    final controller = TextEditingController();
    String banType = 'ip';
    
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.translate('admin_ban')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'ip', label: Text('IP')),
                      ButtonSegment(value: 'words', label: Text(l10n.translate('words'))),
                    ],
                    selected: {banType},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() => banType = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: banType == 'ip' ? 'IP' : l10n.translate('words'),
                      hintText: banType == 'ip' ? '192.168.1.100' : l10n.translate('banned_word'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.translate('cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isNotEmpty) {
                      final key = 'ban.$banType';
                      final currentList = (widget.socket.serverConfig?['ban']?[banType] as List?) ?? [];
                      final newList = [...currentList, value];
                      widget.socket.updateConfig(key, newList);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.translate('admin_ban_added'))),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(l10n.translate('ban')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  dynamic _getConfigValue(String key) {
    final parts = key.split('.');
    if (parts.length != 2) return null;
    final section = parts[0];
    final field = parts[1];
    return widget.socket.serverConfig?[section]?[field];
  }
  
  String _getConfigHint(String key) {
    if (key.contains('check') || key.contains('allow')) {
      return 'true or false';
    }
    if (key.contains('length') || key.contains('size')) {
      return 'number (e.g., 16384)';
    }
    return 'value';
  }

  void _showUnbanDialog() {
    String banType = 'ip';
    
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentList = (widget.socket.serverConfig?['ban']?[banType] as List?)?.cast<String>() ?? [];
            
            return AlertDialog(
              title: Text(l10n.translate('admin_unban')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'ip', label: Text('IP')),
                      ButtonSegment(value: 'words', label: Text(l10n.translate('words'))),
                    ],
                    selected: {banType},
                    onSelectionChanged: (Set<String> selection) {
                      setDialogState(() => banType = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (currentList.isEmpty)
                    Text(l10n.translate('no_banned_items'))
                  else
                    SizedBox(
                      width: double.maxFinite,
                      height: 200,
                      child: ListView.builder(
                        itemCount: currentList.length,
                        itemBuilder: (context, index) {
                          final item = currentList[index];
                          return ListTile(
                            title: Text(item),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.green),
                              onPressed: () {
                                final newList = [...currentList]..removeAt(index);
                                widget.socket.updateConfig('ban.$banType', newList);
                                Future.delayed(const Duration(milliseconds: 50), () {
                                  if (context.mounted) {
                                    setDialogState(() {});
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.translate('admin_unban_success'))),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.translate('close')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!widget.socket.isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.disconnectedFromServer,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    if (!_isAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.translate('admin_unauthorized'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('admin_need_permission'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final pendingUsers = _pendingUsers;
    final onlineUsers = _onlineUsers;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.translate('admin_actions'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _showBroadcastDialog,
              icon: const Icon(Icons.campaign),
              label: Text(l10n.translate('broadcast')),
            ),
            ElevatedButton.icon(
              onPressed: _showConfigDialog,
              icon: const Icon(Icons.settings),
              label: Text(l10n.translate('config')),
            ),
            ElevatedButton.icon(
              onPressed: _showBanDialog,
              icon: const Icon(Icons.block),
              label: Text(l10n.translate('ban')),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
            ),
            ElevatedButton.icon(
              onPressed: _showUnbanDialog,
              icon: const Icon(Icons.check_circle),
              label: Text(l10n.translate('unban')),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[100]),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (pendingUsers.isNotEmpty) ...[
          Text(
            l10n.translate('admin_pending_requests'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...pendingUsers.map((user) {
            final uid = user['uid'] as int;
            final username = user['username'] as String? ?? 'Unknown';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    uid.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(username),
                subtitle: Text('UID: $uid - ${l10n.statusPending}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _acceptUser(uid),
                      tooltip: l10n.translate('accept'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectUser(uid),
                      tooltip: l10n.translate('reject'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
        ],
        Text(
          l10n.translate('admin_online_users'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (onlineUsers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.translate('admin_no_online_users'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
          )
        else
          ...onlineUsers.map((user) {
            final uid = user['uid'] as int;
            final username = user['username'] as String? ?? 'Unknown';
            final status = user['status'] as String? ?? 'Unknown';
            final statusColor = status == 'Root' ? Colors.red : (status == 'Admin' ? Colors.blue : Colors.green);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor,
                  child: Text(
                    uid.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(username),
                subtitle: Text('UID: $uid - $status'),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove, color: Colors.red),
                  onPressed: () => _kickUser(uid),
                  tooltip: l10n.translate('kick'),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}
