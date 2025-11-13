import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _FileTransferState { none, receiving }

class SocketMessage {
  final String type; // 'text', 'file_status', 'user_join'
  final String content;
  final Map<String, dynamic>? metadata;

  SocketMessage(this.type, this.content, [this.metadata]);

  factory SocketMessage.text(String text) => SocketMessage('text', text);

  factory SocketMessage.userJoin(String username) =>
      SocketMessage('user_join', username);

  factory SocketMessage.fileStatus(String statusKey, [List<String>? args]) =>
      SocketMessage('file_status', statusKey, {'args': args ?? []});
}

class SocketService {
  Socket? _socket;
  StreamSubscription<Uint8List>? _socketSubscription;
  final _messageController = StreamController<SocketMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _buffer = <int>[];
  Map<String, dynamic>? serverInfo;

  _FileTransferState _fileState = _FileTransferState.none;
  String? _currentFilename;
  int? _currentFileSize;
  final List<String> _fileDataChunks = [];

  Stream<SocketMessage> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  bool get isConnected => _socket != null;

  Future<void> _saveReceivedFile(String filename, List<String> chunks) async {
    if (_messageController.isClosed) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoSave = prefs.getBool('auto_save_files') ?? true;

      if (!autoSave) {
        _messageController.add(
          SocketMessage.fileStatus('file_received', [filename]),
        );
        return;
      }

      final List<int> bytes = [];
      for (final chunk in chunks) {
        bytes.addAll(base64Decode(chunk));
      }

      if (_currentFileSize != null && bytes.length != _currentFileSize) {
        _messageController.add(SocketMessage.fileStatus('file_size_mismatch'));
      }

      String? downloadPath = prefs.getString('download_path');
      Directory? directory;

      if (downloadPath != null && downloadPath.isNotEmpty) {
        directory = Directory(downloadPath);
        if (!directory.existsSync()) {
          try {
            directory.createSync(recursive: true);
          } catch (e) {
            _messageController.add(
              SocketMessage.fileStatus('cannot_create_dir', ['$e']),
            );
            downloadPath = null;
          }
        }
      }

      if (downloadPath == null || downloadPath.isEmpty) {
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        }
      }

      if (directory == null) {
        _messageController.add(SocketMessage.fileStatus('cannot_get_dir'));
        return;
      }

      var filePath = path.join(directory.path, filename);
      var counter = 1;
      while (File(filePath).existsSync()) {
        final extension = path.extension(filename);
        final nameWithoutExt = path.basenameWithoutExtension(filename);
        if (extension.isNotEmpty) {
          filePath = path.join(
            directory.path,
            '$nameWithoutExt($counter)$extension',
          );
        } else {
          filePath = path.join(directory.path, '$filename($counter)');
        }
        counter++;
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _messageController.add(
        SocketMessage.fileStatus('file_saved', [file.path]),
      );
    } catch (e) {
      _messageController.add(
        SocketMessage.fileStatus('file_save_failed', ['$e']),
      );
    }
  }

  Future<bool> connect(String ip, int port, String username) async {
    try {
      _socket = await Socket.connect(ip, port);
      try {
        _socket!.setOption(SocketOption.tcpNoDelay, true);
        if (Platform.isWindows) {
          _socket!.setRawOption(
            RawSocketOption(
              0xFFFF, // SOL_SOCKET
              0x0008, // SO_KEEPALIVE
              Uint8List.fromList([1, 0, 0, 0]), // TRUE
            ),
          );
        } else {
          _socket!.setRawOption(
            RawSocketOption(
              1, // SOL_SOCKET
              9, // SO_KEEPALIVE
              Uint8List.fromList([1, 0, 0, 0]), // TRUE
            ),
          );
          try {
            // TCP_KEEPIDLE = 180 * 60 = 10800秒
            final idleBytes = Uint8List(4);
            final idleValue = 10800;
            idleBytes[0] = idleValue & 0xFF;
            idleBytes[1] = (idleValue >> 8) & 0xFF;
            idleBytes[2] = (idleValue >> 16) & 0xFF;
            idleBytes[3] = (idleValue >> 24) & 0xFF;
            _socket!.setRawOption(RawSocketOption(6, 4, idleBytes));

            // TCP_KEEPINTVL = 30
            final intvlBytes = Uint8List(4);
            final intvlValue = 30;
            intvlBytes[0] = intvlValue & 0xFF;
            intvlBytes[1] = (intvlValue >> 8) & 0xFF;
            intvlBytes[2] = (intvlValue >> 16) & 0xFF;
            intvlBytes[3] = (intvlValue >> 24) & 0xFF;
            _socket!.setRawOption(RawSocketOption(6, 5, intvlBytes));
          } catch (_) {
          }
        }
      } catch (e) {
      }

      _socket!.write('用户 $username 加入聊天室。\n');
      serverInfo = {'ip': ip, 'port': port, 'username': username};
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
        SocketMessage('connection_lost', 'disconnected_from_server'),
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
      if (line.startsWith('{') && line.endsWith('}')) {
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final type = json['type'] as String?;

          if (type == '[FILE_START]') {
            _fileState = _FileTransferState.receiving;
            _currentFilename = json['name'] as String?;
            _currentFileSize = json['size'] as int?;
            _fileDataChunks.clear();
            final filename = _currentFilename ?? 'unknown';
            _messageController.add(
              SocketMessage.fileStatus('receiving_file', [filename]),
            );
            continue;
          } else if (type == '[FILE_DATA]' &&
              _fileState == _FileTransferState.receiving) {
            final data = json['data'] as String?;
            if (data != null) {
              _fileDataChunks.add(data);
            }
            continue;
          } else if (type == '[FILE_END]' &&
              _fileState == _FileTransferState.receiving) {
            final filename = _currentFilename ?? 'unknown';

            await _saveReceivedFile(filename, _fileDataChunks);

            _fileState = _FileTransferState.none;
            _currentFilename = null;
            _currentFileSize = null;
            _fileDataChunks.clear();
            continue;
          }
        } catch (_) {
          continue;
        }
      }

      _messageController.add(SocketMessage.text(line));
    }
  }

  void send(String username, String message) {
    if (_socket == null) return;
    _socket!.write('$username: $message\n');
  }

  void sendAdmin(String type, String message) {
    if (_socket == null) return;
    final json = jsonEncode({'type': type, 'message': message});
    _socket!.write('$json\n');
  }

  void sendFile(String filename, Uint8List bytes) {
    if (_socket == null) return;
    final start = jsonEncode({
      'type': '[FILE_START]',
      'name': filename,
      'size': bytes.length,
    });
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
    if (_socket == null) return;
    
    _socketSubscription?.cancel();
    _socketSubscription = null;
    if (!_connectionController.isClosed) {
      _connectionController.add(false);
    }
    _socket?.close();
    _socket = null;
    serverInfo = null;
    _buffer.clear();
    _fileState = _FileTransferState.none;
    _currentFilename = null;
    _currentFileSize = null;
    _fileDataChunks.clear();
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
