import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class SocketMessage {
  final Map<String, dynamic> data;

  SocketMessage(this.data);

  String get type => data['type'] as String? ?? '';
  
  factory SocketMessage.fromJson(Map<String, dynamic> json) => SocketMessage(json);
}

class SocketService {
  Socket? _socket;
  StreamSubscription<Uint8List>? _socketSubscription;
  final _messageController = StreamController<SocketMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _buffer = <int>[];
  
  int? myUid;
  String? myUsername;
  Map<String, dynamic>? serverConfig;
  List<Map<String, dynamic>>? users;

  Stream<SocketMessage> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  bool get isConnected => _socket != null;

  Future<bool> connect(String ip, int port, String username) async {
    try {
      _socket = await Socket.connect(ip, port);
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      if (Platform.isWindows) {
        _socket!.setRawOption(
          RawSocketOption(0xFFFF, 0x0008, Uint8List.fromList([1, 0, 0, 0])),
        );
      } else {
        _socket!.setRawOption(
          RawSocketOption(1, 9, Uint8List.fromList([1, 0, 0, 0])),
        );
        try {
          final idleBytes = Uint8List(4)
            ..[0] = 10800 & 0xFF
            ..[1] = (10800 >> 8) & 0xFF
            ..[2] = (10800 >> 16) & 0xFF
            ..[3] = (10800 >> 24) & 0xFF;
          _socket!.setRawOption(RawSocketOption(6, 4, idleBytes));

          final intvlBytes = Uint8List(4)
            ..[0] = 30 & 0xFF
            ..[1] = (30 >> 8) & 0xFF
            ..[2] = (30 >> 16) & 0xFF
            ..[3] = (30 >> 24) & 0xFF;
          _socket!.setRawOption(RawSocketOption(6, 5, intvlBytes));
        } catch (_) {}
      }

      myUsername = username;
      final request = jsonEncode({'type': 'GATE.REQUEST', 'username': username});
      _socket!.write('$request\n');
      
      _connectionController.add(true);
      _listen();
      return true;
    } catch (e) {
      _connectionController.add(false);
      return false;
    }
  }

  void _listen() {
    _socketSubscription = _socket?.listen(
      (data) {
        _buffer.addAll(data);
        _processBuffer();
      },
      onError: (_) => _handleDisconnection(),
      onDone: _handleDisconnection,
      cancelOnError: false,
    );
  }

  void _handleDisconnection() {
    if (_socket == null) return;
    if (!_messageController.isClosed) {
      _messageController.add(
        SocketMessage({'type': 'CONNECTION_LOST'}),
      );
    }
    disconnect();
  }

  Future<void> _processBuffer() async {
    if (_messageController.isClosed) return;
    
    while (_buffer.contains(10)) {
      final idx = _buffer.indexOf(10);
      final line = utf8.decode(_buffer.sublist(0, idx));
      _buffer.removeRange(0, idx + 1);

      if (line.isEmpty) continue;
      
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        final type = json['type'] as String?;
        
        if (type == 'SERVER.DATA') {
          myUid = json['uid'] as int?;
          serverConfig = json['config'] as Map<String, dynamic>?;
          if (serverConfig != null) {
            serverConfig!['server_version'] = json['server_version'];
          }
          final usersList = (json['users'] as List?)?.cast<Map<String, dynamic>>();
          if (usersList != null) {
            users = [];
            for (var i = 0; i < usersList.length; i++) {
              final user = Map<String, dynamic>.from(usersList[i]);
              user['uid'] = i;
              users!.add(user);
            }
          }

          final chatHistory = (json['chat_history'] as List?)?.cast<Map<String, dynamic>>();
          if (chatHistory != null && chatHistory.isNotEmpty) {
            json['_chat_history'] = chatHistory;
          }
        }

        if (type == 'GATE.CLIENT_REQUEST.ANNOUNCE') {
          final username = json['username'] as String?;
          final uid = json['uid'] as int?;
          final result = json['result'] as String?;
          if (username != null && uid != null && users != null) {
            while (users!.length <= uid) {
              users!.add({'username': 'Unknown', 'status': 'Offline'});
            }
            users![uid]['username'] = username;
            if (result == 'Accepted') {
              users![uid]['status'] = 'Online';
            } else if (result == 'Pending review') {
              users![uid]['status'] = 'Pending';
            }
          }
        }
        
        if (type == 'GATE.STATUS_CHANGE.ANNOUNCE') {
          final uid = json['uid'] as int?;
          final status = json['status'] as String?;
          if (uid != null && status != null && users != null && uid < users!.length) {
            users![uid]['status'] = status;
          }
        }
        
        if (type == 'SERVER.CONFIG.CHANGE') {
          final key = json['key'] as String?;
          final value = json['value'];
          if (key != null && serverConfig != null) {
            final parts = key.split('.');
            if (parts.length == 2) {
              final section = parts[0];
              final field = parts[1];
              if (serverConfig![section] is Map) {
                serverConfig![section][field] = value;
              }
            }
          }
        }
        
        _messageController.add(SocketMessage.fromJson(json));
      } catch (_) {
        continue;
      }
    }
  }

  void sendMessage(String content, {int to = -1}) {
    if (_socket == null) return;
    final msg = jsonEncode({
      'type': 'CHAT.SEND',
      'filename': '',
      'content': content,
      'to': to,
    });
    _socket!.write('$msg\n');
  }

  void sendFile(String filename, Uint8List bytes, {int to = -1}) {
    if (_socket == null) return;
    final content = base64Encode(bytes);
    final msg = jsonEncode({
      'type': 'CHAT.SEND',
      'filename': filename,
      'content': content,
      'to': to,
    });
    _socket!.write('$msg\n');
  }

  void sendBroadcast(String content) {
    if (_socket == null) return;
    final msg = jsonEncode({
      'type': 'CHAT.SEND',
      'filename': '',
      'content': content,
      'to': -2,
    });
    _socket!.write('$msg\n');
  }

  void kickUser(int uid) {
    if (_socket == null) return;
    final msg = jsonEncode({
      'type': 'GATE.STATUS_CHANGE.REQUEST',
      'status': 'Kicked',
      'uid': uid,
    });
    _socket!.write('$msg\n');
  }

  void acceptUser(int uid) {
    if (_socket == null) return;
    final msg = jsonEncode({
      'type': 'GATE.STATUS_CHANGE.REQUEST',
      'status': 'Online',
      'uid': uid,
    });
    _socket!.write('$msg\n');
  }

  void rejectUser(int uid) {
    if (_socket == null) return;
    final msg = jsonEncode({
      'type': 'GATE.STATUS_CHANGE.REQUEST',
      'status': 'Rejected',
      'uid': uid,
    });
    _socket!.write('$msg\n');
  }

  void updateConfig(String key, dynamic value) {
    if (_socket == null) return;
    final msg = jsonEncode({
      'type': 'SERVER.CONFIG.POST',
      'key': key,
      'value': value,
    });
    _socket!.write('$msg\n');
  }

  void disconnect() {
    if (_socket == null) return;
    
    _socketSubscription?.cancel();
    _socketSubscription = null;
    if (!_connectionController.isClosed) {
      _connectionController.add(false);
    }
    _socket?.close();
    _socket = null;
    myUid = null;
    myUsername = null;
    serverConfig = null;
    users = null;
    _buffer.clear();
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
