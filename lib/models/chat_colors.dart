import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatColors {
  final Color myMessageBubble;
  final Color otherMessageBubble;
  final Color systemMessage;
  final Color banNotification;

  ChatColors({
    required this.myMessageBubble,
    required this.otherMessageBubble,
    required this.systemMessage,
    required this.banNotification,
  });

  static ChatColors light() => ChatColors(
    myMessageBubble: Colors.blue[100]!,
    otherMessageBubble: Colors.grey[300]!,
    systemMessage: Colors.orange[100]!,
    banNotification: Colors.red[100]!,
  );

  static ChatColors dark() => ChatColors(
    myMessageBubble: Colors.blue[900]!,
    otherMessageBubble: Colors.grey[800]!,
    systemMessage: Colors.orange[900]!,
    banNotification: Colors.red[900]!,
  );

  static Future<ChatColors> load(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();

    final defaults = isDark ? dark() : light();

    return ChatColors(
      myMessageBubble: Color(
        prefs.getInt('color_my_message') ?? defaults.myMessageBubble.toARGB32(),
      ),
      otherMessageBubble: Color(
        prefs.getInt('color_other_message') ??
            defaults.otherMessageBubble.toARGB32(),
      ),
      systemMessage: Color(
        prefs.getInt('color_system_message') ??
            defaults.systemMessage.toARGB32(),
      ),
      banNotification: Color(
        prefs.getInt('color_ban_notification') ??
            defaults.banNotification.toARGB32(),
      ),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('color_my_message', myMessageBubble.toARGB32());
    await prefs.setInt('color_other_message', otherMessageBubble.toARGB32());
    await prefs.setInt('color_system_message', systemMessage.toARGB32());
    await prefs.setInt('color_ban_notification', banNotification.toARGB32());
  }

  ChatColors copyWith({
    Color? myMessageBubble,
    Color? otherMessageBubble,
    Color? systemMessage,
    Color? banNotification,
  }) {
    return ChatColors(
      myMessageBubble: myMessageBubble ?? this.myMessageBubble,
      otherMessageBubble: otherMessageBubble ?? this.otherMessageBubble,
      systemMessage: systemMessage ?? this.systemMessage,
      banNotification: banNotification ?? this.banNotification,
    );
  }
}
