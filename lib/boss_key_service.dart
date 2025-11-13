import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BossKeyService {
  static final BossKeyService _instance = BossKeyService._internal();
  factory BossKeyService() => _instance;
  BossKeyService._internal();

  HotKey? _hotKey;
  bool _isRegistered = false;

  bool get isRegistered => _isRegistered;

  static const String _defaultKeyCode = 'Backquote';
  static const List<String> _defaultModifiers = ['control'];

  Future<String> getKeyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('boss_key_code') ?? _defaultKeyCode;
  }

  Future<List<String>> getModifiers() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('boss_key_modifiers');
    return stored ?? _defaultModifiers;
  }

  Future<void> saveShortcut(String keyCode, List<String> modifiers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('boss_key_code', keyCode);
    await prefs.setStringList('boss_key_modifiers', modifiers);
  }

  Future<void> resetToDefault() async {
    await saveShortcut(_defaultKeyCode, _defaultModifiers);
  }

  String formatShortcut(List<String> modifiers, String keyCode) {
    final parts = [
      ...modifiers.map((m) {
        switch (m.toLowerCase()) {
          case 'control': return 'Ctrl';
          case 'alt': return 'Alt';
          case 'shift': return 'Shift';
          case 'meta': return 'Win';
          default: return m;
        }
      }),
      _formatKeyName(keyCode),
    ];
    return parts.join(' + ');
  }

  String _formatKeyName(String keyCode) {
    final name = keyCode.replaceAll('Key', '').replaceAll('Digit', '');
    if (name == 'Backquote') return '`';
    if (name == 'Minus') return '-';
    if (name == 'Equal') return '=';
    if (name == 'BracketLeft') return '[';
    if (name == 'BracketRight') return ']';
    if (name == 'Backslash') return '\\';
    if (name == 'Semicolon') return ';';
    if (name == 'Quote') return "'";
    if (name == 'Comma') return ',';
    if (name == 'Period') return '.';
    if (name == 'Slash') return '/';
    if (name == 'Space') return 'Space';
    return name;
  }

  PhysicalKeyboardKey? _parseKeyCode(String keyCode) {
    final keyMap = {
      'Backquote': PhysicalKeyboardKey.backquote,
      'Minus': PhysicalKeyboardKey.minus,
      'Equal': PhysicalKeyboardKey.equal,
      'BracketLeft': PhysicalKeyboardKey.bracketLeft,
      'BracketRight': PhysicalKeyboardKey.bracketRight,
      'Backslash': PhysicalKeyboardKey.backslash,
      'Semicolon': PhysicalKeyboardKey.semicolon,
      'Quote': PhysicalKeyboardKey.quote,
      'Comma': PhysicalKeyboardKey.comma,
      'Period': PhysicalKeyboardKey.period,
      'Slash': PhysicalKeyboardKey.slash,
      'Space': PhysicalKeyboardKey.space,
    };

    if (keyMap.containsKey(keyCode)) {
      return keyMap[keyCode];
    }

    if (keyCode.startsWith('Key')) {
      final letter = keyCode.substring(3).toLowerCase();
      final letterMap = {
        'a': PhysicalKeyboardKey.keyA, 'b': PhysicalKeyboardKey.keyB,
        'c': PhysicalKeyboardKey.keyC, 'd': PhysicalKeyboardKey.keyD,
        'e': PhysicalKeyboardKey.keyE, 'f': PhysicalKeyboardKey.keyF,
        'g': PhysicalKeyboardKey.keyG, 'h': PhysicalKeyboardKey.keyH,
        'i': PhysicalKeyboardKey.keyI, 'j': PhysicalKeyboardKey.keyJ,
        'k': PhysicalKeyboardKey.keyK, 'l': PhysicalKeyboardKey.keyL,
        'm': PhysicalKeyboardKey.keyM, 'n': PhysicalKeyboardKey.keyN,
        'o': PhysicalKeyboardKey.keyO, 'p': PhysicalKeyboardKey.keyP,
        'q': PhysicalKeyboardKey.keyQ, 'r': PhysicalKeyboardKey.keyR,
        's': PhysicalKeyboardKey.keyS, 't': PhysicalKeyboardKey.keyT,
        'u': PhysicalKeyboardKey.keyU, 'v': PhysicalKeyboardKey.keyV,
        'w': PhysicalKeyboardKey.keyW, 'x': PhysicalKeyboardKey.keyX,
        'y': PhysicalKeyboardKey.keyY, 'z': PhysicalKeyboardKey.keyZ,
      };
      return letterMap[letter];
    }

    if (keyCode.startsWith('Digit')) {
      final digit = keyCode.substring(5);
      final digitMap = {
        '0': PhysicalKeyboardKey.digit0, '1': PhysicalKeyboardKey.digit1,
        '2': PhysicalKeyboardKey.digit2, '3': PhysicalKeyboardKey.digit3,
        '4': PhysicalKeyboardKey.digit4, '5': PhysicalKeyboardKey.digit5,
        '6': PhysicalKeyboardKey.digit6, '7': PhysicalKeyboardKey.digit7,
        '8': PhysicalKeyboardKey.digit8, '9': PhysicalKeyboardKey.digit9,
      };
      return digitMap[digit];
    }

    final fnMap = {
      'F1': PhysicalKeyboardKey.f1, 'F2': PhysicalKeyboardKey.f2,
      'F3': PhysicalKeyboardKey.f3, 'F4': PhysicalKeyboardKey.f4,
      'F5': PhysicalKeyboardKey.f5, 'F6': PhysicalKeyboardKey.f6,
      'F7': PhysicalKeyboardKey.f7, 'F8': PhysicalKeyboardKey.f8,
      'F9': PhysicalKeyboardKey.f9, 'F10': PhysicalKeyboardKey.f10,
      'F11': PhysicalKeyboardKey.f11, 'F12': PhysicalKeyboardKey.f12,
    };
    return fnMap[keyCode];
  }

  List<HotKeyModifier> _parseModifiers(List<String> modifiers) {
    return modifiers.map((m) {
      switch (m.toLowerCase()) {
        case 'control': return HotKeyModifier.control;
        case 'alt': return HotKeyModifier.alt;
        case 'shift': return HotKeyModifier.shift;
        case 'meta': return HotKeyModifier.meta;
        default: return HotKeyModifier.control;
      }
    }).toList();
  }

  Future<void> register() async {
    if (kIsWeb || !Platform.isWindows) return;
    
    await unregister();
    
    final keyCode = await getKeyCode();
    final modifiers = await getModifiers();
    
    final key = _parseKeyCode(keyCode);
    if (key == null) return;

    _hotKey = HotKey(
      key: key,
      modifiers: _parseModifiers(modifiers),
      scope: HotKeyScope.system,
    );

    try {
      await hotKeyManager.register(
        _hotKey!,
        keyDownHandler: (_) async {
          final visible = await windowManager.isVisible();
          if (visible) {
            await windowManager.hide();
          } else {
            await windowManager.show();
            await windowManager.focus();
          }
        },
      );
      _isRegistered = true;
    } catch (e) {
      _hotKey = null;
      _isRegistered = false;
      rethrow;
    }
  }

  Future<void> unregister() async {
    if (kIsWeb || !Platform.isWindows) return;
    if (!_isRegistered || _hotKey == null) return;

    try {
      await hotKeyManager.unregister(_hotKey!);
    } catch (e) {
    }
    
    _hotKey = null;
    _isRegistered = false;
  }

  Future<void> dispose() async {
    await unregister();
  }
}
