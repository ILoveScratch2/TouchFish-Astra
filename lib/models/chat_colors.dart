import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatColors {
  final Color myMessageBubble;
  final Color otherMessageBubble;
  final Color systemMessage;
  final Color banNotification;
  final Color fileBubble;
  final Color privateBubble;
  final Color myPrivateBubble;

  ChatColors({
    required this.myMessageBubble,
    required this.otherMessageBubble,
    required this.systemMessage,
    required this.banNotification,
    required this.fileBubble,
    required this.privateBubble,
    required this.myPrivateBubble,
  });

  static ChatColors light() => ChatColors(
    myMessageBubble: Colors.blue[100]!,
    otherMessageBubble: Colors.grey[300]!,
    systemMessage: Colors.orange[100]!,
    banNotification: Colors.red[100]!,
    fileBubble: Colors.amber[100]!,
    privateBubble: Colors.green[100]!,
    myPrivateBubble: Colors.purple[100]!,
  );

  static ChatColors dark() => ChatColors(
    myMessageBubble: Colors.blue[900]!,
    otherMessageBubble: Colors.grey[800]!,
    systemMessage: Colors.orange[900]!,
    banNotification: Colors.red[900]!,
    fileBubble: Colors.amber[900]!,
    privateBubble: Colors.green[900]!,
    myPrivateBubble: Colors.purple[900]!,
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
      fileBubble: Color(
        prefs.getInt('color_file_bubble') ?? defaults.fileBubble.toARGB32(),
      ),
      privateBubble: Color(
        prefs.getInt('color_private_bubble') ?? defaults.privateBubble.toARGB32(),
      ),
      myPrivateBubble: Color(
        prefs.getInt('color_my_private_bubble') ?? defaults.myPrivateBubble.toARGB32(),
      ),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('color_my_message', myMessageBubble.toARGB32());
    await prefs.setInt('color_other_message', otherMessageBubble.toARGB32());
    await prefs.setInt('color_system_message', systemMessage.toARGB32());
    await prefs.setInt('color_ban_notification', banNotification.toARGB32());
    await prefs.setInt('color_file_bubble', fileBubble.toARGB32());
    await prefs.setInt('color_private_bubble', privateBubble.toARGB32());
    await prefs.setInt('color_my_private_bubble', myPrivateBubble.toARGB32());
  }

  ChatColors copyWith({
    Color? myMessageBubble,
    Color? otherMessageBubble,
    Color? systemMessage,
    Color? banNotification,
    Color? fileBubble,
    Color? privateBubble,
    Color? myPrivateBubble,
  }) {
    return ChatColors(
      myMessageBubble: myMessageBubble ?? this.myMessageBubble,
      otherMessageBubble: otherMessageBubble ?? this.otherMessageBubble,
      systemMessage: systemMessage ?? this.systemMessage,
      banNotification: banNotification ?? this.banNotification,
      fileBubble: fileBubble ?? this.fileBubble,
      privateBubble: privateBubble ?? this.privateBubble,
      myPrivateBubble: myPrivateBubble ?? this.myPrivateBubble,
    );
  }
}
