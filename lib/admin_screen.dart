import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'socket_service.dart';
import 'app_localizations.dart';

class AdminCommand {
  final String type;
  final String labelKey;
  final String hintKey;
  final bool hasArg;
  final IconData icon;
  final int maxLines;
  final List<String>? options;

  const AdminCommand({
    required this.type,
    required this.labelKey,
    required this.hintKey,
    required this.hasArg,
    required this.icon,
    this.maxLines = 1,
    this.options,
  });
}

class AdminScreen extends StatefulWidget {
  final SocketService socket;

  const AdminScreen({super.key, required this.socket});

  @override
  AdminScreenState createState() => AdminScreenState();
}

enum AdminConnectionState { disconnected, connecting, connected, unauthorized }

class AdminScreenState extends State<AdminScreen> {
  final _controllers = <String, TextEditingController>{};
  final _dropdownValues = <String, String>{};
  final _results = <String>[];
  final _portController = TextEditingController(text: '11451');
  
  Socket? _adminSocket;
  AdminConnectionState _connectionState = AdminConnectionState.disconnected;
  final _buffer = <int>[];
  Timer? _heartbeatTimer;

  static const _commands = [
    AdminCommand(
      type: 'broadcast',
      labelKey: 'admin_broadcast',
      hintKey: 'admin_broadcast_hint',
      hasArg: true,
      icon: Icons.campaign,
      maxLines: 3,
    ),
    AdminCommand(
      type: 'ban',
      labelKey: 'admin_ban',
      hintKey: 'admin_ban_hint',
      hasArg: true,
      icon: Icons.block,
    ),
    AdminCommand(
      type: 'enable',
      labelKey: 'admin_enable',
      hintKey: 'admin_enable_hint',
      hasArg: true,
      icon: Icons.check_circle,
    ),
    AdminCommand(
      type: 'set',
      labelKey: 'admin_set',
      hintKey: 'admin_set_hint',
      hasArg: true,
      icon: Icons.settings_suggest,
      options: ['EAP on', 'EAP off', 'SEM on', 'SEM off', 'SEM off forever', 'ARO on', 'ARO off'],
    ),
    AdminCommand(
      type: 'accept',
      labelKey: 'admin_accept',
      hintKey: 'admin_accept_hint',
      hasArg: true,
      icon: Icons.person_add,
    ),
    AdminCommand(
      type: 'reject',
      labelKey: 'admin_reject',
      hintKey: 'admin_reject_hint',
      hasArg: true,
      icon: Icons.person_remove,
    ),
    AdminCommand(
      type: 'search',
      labelKey: 'admin_search',
      hintKey: 'admin_search_hint',
      hasArg: true,
      icon: Icons.search,
      options: ['online', 'offline', 'banned', 'user', 'ip', 'send_times'],
    ),
    AdminCommand(
      type: 'req',
      labelKey: 'admin_req',
      hintKey: 'admin_req_hint',
      hasArg: false,
      icon: Icons.list_alt,
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final cmd in _commands) {
      if (cmd.hasArg) {
        _controllers[cmd.type] = TextEditingController();
      }
      if (cmd.options != null && cmd.options!.isNotEmpty) {
        _dropdownValues[cmd.type] = cmd.options!.first;
      }
    }
  }

  @override
  void dispose() {
    _disconnectAdmin();
    _portController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _connectAdmin() async {
    final l10n = AppLocalizations.of(context);
    final port = int.tryParse(_portController.text.trim());
    if (port == null) {
      _showError(l10n.translate('admin_invalid_port'));
      return;
    }

    setState(() => _connectionState = AdminConnectionState.connecting);

    try {
      final serverInfo = widget.socket.serverInfo;
      if (serverInfo == null) {
        throw Exception('Chat not connected');
      }

      _adminSocket = await Socket.connect(serverInfo['ip'], port)
          .timeout(const Duration(seconds: 5));

      _adminSocket!.setOption(SocketOption.tcpNoDelay, true);
      _adminSocket!.listen(
        _onAdminData,
        onError: (_) => _onAdminDisconnected(),
        onDone: _onAdminDisconnected,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final username = serverInfo['username'] ?? 'Admin';
      _sendAdminCommand('username', username);

      _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (_adminSocket != null) {
          try {
            _adminSocket!.write('{"type":"test","message":""}\n');
          } catch (_) {}
        }
      });

      setState(() => _connectionState = AdminConnectionState.connected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('admin_connected'))),
        );
      }
    } catch (e) {
      setState(() => _connectionState = AdminConnectionState.unauthorized);
      _showError(l10n.translate('admin_connect_failed'));
    }
  }

  void _onAdminData(List<int> data) {
    _buffer.addAll(data);
    
    while (true) {
      final bracketStart = _buffer.indexOf(123);
      if (bracketStart == -1) break;

      var depth = 0;
      var end = -1;
      for (var i = bracketStart; i < _buffer.length; i++) {
        if (_buffer[i] == 123) depth++;
        if (_buffer[i] == 125) {
          depth--;
          if (depth == 0) {
            end = i + 1;
            break;
          }
        }
      }

      if (end == -1) break;

      final jsonBytes = _buffer.sublist(bracketStart, end);
      _buffer.removeRange(0, end);

      try {
        final line = utf8.decode(jsonBytes);
        final json = jsonDecode(line) as Map<String, dynamic>;
        final type = json['type'] as String?;

        if (type == 'removed') {
          _onAdminDisconnected();
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            _showError(l10n.translate('admin_removed'));
          }
          return;
        }

        if (type == 'server_closed') {
          _onAdminDisconnected();
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            _showError(l10n.translate('admin_server_closed'));
          }
          return;
        }

        if (type == 'result') {
          var msg = json['message'] as String? ?? '';
          if (msg.isNotEmpty && mounted) {
            setState(() {
              final lines = msg.split('\n').where((l) => l.trim().isNotEmpty);
              for (final line in lines) {
                _results.insert(0, line);
              }
              while (_results.length > 100) {
                _results.removeLast();
              }
            });
          }
        }
      } catch (e) {
        print('Admin JSON parse error: $e');
      }
    }
  }

  void _onAdminDisconnected() {
    _disconnectAdmin();
    if (mounted) {
      setState(() => _connectionState = AdminConnectionState.disconnected);
    }
  }

  void _disconnectAdmin() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _adminSocket?.close();
    _adminSocket = null;
  }

  void _sendAdminCommand(String type, String message) {
    if (_adminSocket == null) return;
    try {
      final json = jsonEncode({'type': type, 'message': message});
      _adminSocket!.write('$json\n');
    } catch (_) {}
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _executeCommand(AdminCommand cmd) {
    String arg;
    
    if (cmd.options != null) {
      final selected = _dropdownValues[cmd.type] ?? cmd.options!.first;
      final needsParam = ['user', 'ip', 'send_times'].contains(selected);
      
      if (needsParam) {
        final param = _controllers[cmd.type]?.text.trim() ?? '';
        if (param.isEmpty) {
          final l10n = AppLocalizations.of(context);
          _showError(l10n.fillAllFields);
          return;
        }
        arg = '$selected $param';
      } else {
        arg = selected;
      }
    } else if (cmd.hasArg) {
      arg = _controllers[cmd.type]!.text.trim();
      if (arg.isEmpty) {
        final l10n = AppLocalizations.of(context);
        _showError(l10n.fillAllFields);
        return;
      }
    } else {
      arg = '';
    }
    
    _sendAdminCommand(cmd.type, arg);
    if (cmd.hasArg && _controllers[cmd.type] != null) {
      _controllers[cmd.type]!.clear();
    }
  }

  Widget _buildCommand(AdminCommand cmd) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.translate(cmd.labelKey);
    final hint = l10n.translate(cmd.hintKey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(cmd.icon, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (cmd.options != null) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _dropdownValues[cmd.type],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: cmd.type == 'search' 
                      ? l10n.translate('admin_search_type')
                      : l10n.translate('admin_set_option'),
                  isDense: true,
                ),
                items: cmd.options!.map((opt) {
                  return DropdownMenuItem(
                    value: opt,
                    child: Text(opt),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _dropdownValues[cmd.type] = val);
                  }
                },
              ),
              if (cmd.type == 'search' && ['user', 'ip', 'send_times'].contains(_dropdownValues[cmd.type])) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _controllers[cmd.type],
                  decoration: InputDecoration(
                    hintText: _dropdownValues[cmd.type] == 'send_times'
                        ? l10n.translate('admin_search_times_hint')
                        : l10n.translate('admin_search_param_hint'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _executeCommand(cmd),
                ),
              ],
            ] else if (cmd.hasArg) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _controllers[cmd.type],
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: cmd.maxLines,
                onSubmitted: (_) => _executeCommand(cmd),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _executeCommand(cmd),
                icon: const Icon(Icons.send),
                label: Text(l10n.translate('admin_execute')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionPanel() {
    final l10n = AppLocalizations.of(context);
    final isConnecting = _connectionState == AdminConnectionState.connecting;

    return Center(
      child: SizedBox(
        width: 400,
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 64,
                  color: _connectionState == AdminConnectionState.unauthorized
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.translate('admin_connect_title'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('admin_connect_hint'),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _portController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('admin_port'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isConnecting,
                  onSubmitted: (_) => _connectAdmin(),
                ),
                if (_connectionState == AdminConnectionState.unauthorized) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.translate('admin_unauthorized'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isConnecting ? null : _connectAdmin,
                    icon: isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      isConnecting
                          ? l10n.translate('admin_connecting')
                          : l10n.translate('admin_connect_button'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_connectionState != AdminConnectionState.connected) {
      return _buildConnectionPanel();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.translate('admin_status_connected'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _onAdminDisconnected,
                icon: const Icon(Icons.logout, size: 18),
                label: Text(l10n.translate('admin_disconnect')),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _commands.length,
            itemBuilder: (_, i) => _buildCommand(_commands[i]),
          ),
        ),
        if (_results.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.translate('admin_results'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.clear_all, size: 18),
                        onPressed: () => setState(() => _results.clear()),
                        tooltip: l10n.translate('admin_clear'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _results.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _results[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
