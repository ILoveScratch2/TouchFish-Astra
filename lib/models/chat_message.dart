import '../socket_service.dart';

enum MessageType { chat, gateRequest, gateStatus, gateClientRequest, serverConfig, file, system }

class ChatMessage {
  final MessageType type;
  final Map<String, dynamic> rawData;
  final DateTime timestamp;

  ChatMessage({
    required this.type,
    required this.rawData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromSocketMessage(SocketMessage msg, int? myUid) {
    final type = msg.type;
    
    if (type.startsWith('CHAT.')) {
      return ChatMessage(type: MessageType.chat, rawData: msg.data);
    }
    if (type == 'GATE.CLIENT_REQUEST.ANNOUNCE') {
      return ChatMessage(type: MessageType.gateClientRequest, rawData: msg.data);
    }
    if (type.startsWith('GATE.STATUS_CHANGE')) {
      return ChatMessage(type: MessageType.gateStatus, rawData: msg.data);
    }
    if (type == 'GATE.REVIEW_RESULT' || type == 'GATE.RESPONSE') {
      return ChatMessage(type: MessageType.system, rawData: msg.data);
    }
    if (type.startsWith('GATE.')) {
      return ChatMessage(type: MessageType.gateRequest, rawData: msg.data);
    }
    if (type.startsWith('SERVER.CONFIG')) {
      return ChatMessage(type: MessageType.serverConfig, rawData: msg.data);
    }
    if (type.startsWith('SERVER.')) {
      return ChatMessage(type: MessageType.system, rawData: msg.data);
    }
    
    return ChatMessage(type: MessageType.system, rawData: msg.data);
  }
  String? get content => rawData['content'] as String?;
  int? get from => rawData['from'] as int?;
  int? get to => rawData['to'] as int?;
  String? get filename => rawData['filename'] as String?;
  int? get uid => rawData['uid'] as int?;
  String? get username => rawData['username'] as String?;
  String? get status => rawData['status'] as String?;
  String? get result => rawData['result'] as String?;
  int? get operator => rawData['operator'] as int?;
  
  bool get isFile => filename != null && filename!.isNotEmpty;
  
  bool isMine(int? myUid) {
    if (myUid == null) return false;
    return from == myUid;
  }
  
  bool isToMe(int? myUid) {
    if (myUid == null) return false;
    return to == myUid;
  }
  
  bool get isBroadcast => to == -2;
  bool get isPrivate => to != null && to! >= 0;
  
  String getFileContent() {
    if (!isFile) return '';
    return content ?? '';
  }
}
