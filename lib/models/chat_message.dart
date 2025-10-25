import 'dart:typed_data';
import '../socket_service.dart';

enum MessageType { userMessage, systemMessage, fileTransfer }

class ChatMessage {
  final MessageType type;
  final String sender;
  final String content;
  final List<String> args; // 翻译参数
  final bool isMine;
  final DateTime timestamp;
  final FileTransferInfo? fileInfo;
  final String? filePath;

  ChatMessage({
    required this.type,
    required this.sender,
    required this.content,
    required this.isMine,
    this.args = const [],
    DateTime? timestamp,
    this.fileInfo,
    this.filePath,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromSocketMessage(SocketMessage msg, String myUsername) {
    switch (msg.type) {
      case 'file_status':
        final args = (msg.metadata?['args'] as List?)?.cast<String>() ?? [];
        String? filePath;
        if (msg.content == 'file_saved' && args.isNotEmpty) {
          filePath = args[0];
        }
        
        return ChatMessage(
          type: MessageType.fileTransfer,
          sender: 'system',
          content: msg.content,
          args: args,
          isMine: false,
          filePath: filePath,
        );

      case 'user_join':
        return ChatMessage(
          type: MessageType.systemMessage,
          sender: 'system',
          content: 'user_joined',
          args: [msg.content],
          isMine: false,
        );

      case 'text':
      default:
        return ChatMessage._parseText(msg.content, myUsername);
    }
  }

  factory ChatMessage._parseText(String raw, String myUsername) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return ChatMessage(
        type: MessageType.systemMessage,
        sender: 'system',
        content: '',
        isMine: false,
      );
    }

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return ChatMessage(
        type: MessageType.systemMessage,
        sender: 'system',
        content: trimmed,
        isMine: false,
      );
    }

    if (trimmed.contains('[') && trimmed.contains(']')) {
      final bracketEnd = trimmed.indexOf(']');
      if (bracketEnd > 0 && bracketEnd < 20) {
        return ChatMessage(
          type: MessageType.systemMessage,
          sender: 'system',
          content: trimmed,
          isMine: false,
        );
      }
    }

    if (trimmed.contains(':')) {
      final colonIndex = trimmed.indexOf(':');
      final sender = trimmed.substring(0, colonIndex).trim();
      final content = trimmed.substring(colonIndex + 1).trim();

      return ChatMessage(
        type: MessageType.userMessage,
        sender: sender,
        content: content,
        isMine: sender == myUsername,
      );
    }

    return ChatMessage(
      type: MessageType.systemMessage,
      sender: 'system',
      content: trimmed,
      isMine: false,
    );
  }
}

class FileTransferInfo {
  final String filename;
  final int size;
  final Uint8List? data;

  FileTransferInfo({required this.filename, required this.size, this.data});
}
