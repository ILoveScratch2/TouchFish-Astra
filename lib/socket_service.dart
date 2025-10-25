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
  final _messageController = StreamController<SocketMessage>.broadcast();
  final _buffer = <int>[];

  _FileTransferState _fileState = _FileTransferState.none;
  String? _currentFilename;
  int? _currentFileSize;
  final List<String> _fileDataChunks = [];

  Stream<SocketMessage> get messages => _messageController.stream;

  Future<void> _saveReceivedFile(String filename, List<String> chunks) async {
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

  Future<void> _processBuffer() async {
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
        } catch (_) {}
      }

      _messageController.add(SocketMessage.text(line));
    }
  }

  void send(String username, String message) {
    if (_socket == null) return;
    _socket!.write('$username: $message\n');
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
    _socket?.close();
    _socket = null;
    // Don't close the controller - let subscribers cancel themselves
  }
}
