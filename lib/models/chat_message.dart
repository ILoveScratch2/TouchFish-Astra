import 'dart:typed_data';

enum MessageType { userMessage, systemMessage, fileTransfer }

class ChatMessage {
  final MessageType type;
  final String sender;
  final String content;
  final bool isMine;
  final DateTime timestamp;
  final FileTransferInfo? fileInfo;
  final String? filePath;

  ChatMessage({
    required this.type,
    required this.sender,
    required this.content,
    required this.isMine,
    DateTime? timestamp,
    this.fileInfo,
    this.filePath,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.parse(String raw, String myUsername) {
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
    if (trimmed.contains('[文件传输]')) {
      String? filePath;
      if (trimmed.contains('文件已保存:')) {
        final pathStart = trimmed.indexOf('文件已保存:') + '文件已保存:'.length;
        filePath = trimmed.substring(pathStart).trim();
      }

      return ChatMessage(
        type: MessageType.fileTransfer,
        sender: 'system',
        content: trimmed,
        isMine: false,
        filePath: filePath,
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

    if (trimmed.contains('加入聊天室')) {
      return ChatMessage(
        type: MessageType.systemMessage,
        sender: 'system',
        content: trimmed,
        isMine: false,
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
