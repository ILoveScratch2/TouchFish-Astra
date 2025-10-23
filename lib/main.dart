import 'package:flutter/material.dart';
import 'socket_service.dart';
import 'chat_screen.dart';

void main() => runApp(const TouchFishAstra());

class TouchFishAstra extends StatelessWidget {
  const TouchFishAstra({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TouchFishAstra',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ConnectScreen(),
    );
  }
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _ipController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8080');
  final _usernameController = TextEditingController();
  var _connecting = false;

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final username = _usernameController.text.trim();

    if (ip.isEmpty || port == null || username.isEmpty) {
      _showError('Fill all fields');
      return;
    }

    setState(() => _connecting = true);

    final socket = SocketService();
    final success = await socket.connect(ip, port, username);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(socket: socket, username: username),
        ),
      );
    } else {
      setState(() => _connecting = false);
      _showError('Connection failed');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TouchFishAstra'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TouchFishAstra',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('v0.1.0 by ILoveScratch2'),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Server IP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _connect(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _connecting ? null : _connect,
                      child: _connecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}
