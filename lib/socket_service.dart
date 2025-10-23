import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class SocketService {
  Socket? _socket;
  final _messageController = StreamController<String>.broadcast();
  final _buffer = <int>[];

  Stream<String> get messages => _messageController.stream;

  Future<bool> connect(String ip, int port, String username) async {
    try {
      _socket = await Socket.connect(ip, port);
      _socket!.write('用户 $username 加入聊天室。\n');
      _listen();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _listen() {
    _socket?.listen(
      (data) {
        _buffer.addAll(data);
        _processBuffer();
      },
      onError: (_) => disconnect(),
      onDone: disconnect,
    );
  }

  void _processBuffer() {
    while (_buffer.contains(10)) {
      final idx = _buffer.indexOf(10);
      final line = utf8.decode(_buffer.sublist(0, idx));
      _buffer.removeRange(0, idx + 1);
      if (line.isNotEmpty) _messageController.add(line);
    }
  }

  void send(String username, String message) {
    if (_socket == null) return;
    _socket!.write('$username: $message\n');
  }

  void sendFile(String filename, Uint8List bytes) {
    if (_socket == null) return;
    final start = jsonEncode({'type': '[FILE_START]', 'name': filename, 'size': bytes.length});
    _socket!.write('$start\n');

    for (var i = 0; i < bytes.length; i += 8192) {
      final end = (i + 8192 < bytes.length) ? i + 8192 : bytes.length;
      final chunk = base64Encode(bytes.sublist(i, end));
      final data = jsonEncode({'type': '[FILE_DATA]', 'data': chunk});
      _socket!.write('$data\n');
    }

    final endMsg = jsonEncode({'type': '[FILE_END]'});
    _socket!.write('$endMsg\n');
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
    _messageController.close();
  }
}
