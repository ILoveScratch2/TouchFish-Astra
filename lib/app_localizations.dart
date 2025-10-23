import 'package:flutter/material.dart';

/// Linus式i18n: 只有两种语言，就用最直白的方式
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// 静态访问，这样每个Widget都能方便获取
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// 核心数据结构：一个Map搞定一切
  /// 格式：'key': {'zh': '中文', 'en': 'English'}
  static final Map<String, Map<String, String>> _localizedValues = {
    // App通用
    'settings': {'zh': '设置', 'en': 'Settings'},
    'version': {'zh': '版本', 'en': 'Version'},
    'ok': {'zh': '确定', 'en': 'OK'},
    
    // 连接界面
    'server_ip': {'zh': '服务器IP', 'en': 'Server IP'},
    'port': {'zh': '端口', 'en': 'Port'},
    'username': {'zh': '用户名', 'en': 'Username'},
    'connect': {'zh': '连接', 'en': 'Connect'},
    'fill_all_fields': {'zh': '请填写所有字段', 'en': 'Fill all fields'},
    'connection_failed': {'zh': '连接失败', 'en': 'Connection failed'},
    
    // 设置界面
    'theme': {'zh': '主题', 'en': 'Theme'},
    'theme_dark': {'zh': '深色', 'en': 'Dark'},
    'theme_light': {'zh': '浅色', 'en': 'Light'},
    'language': {'zh': '语言', 'en': 'Language'},
    
    // 聊天界面
    'chat': {'zh': '聊天', 'en': 'Chat'},
    'type_message': {'zh': '输入消息...', 'en': 'Type message...'},
    'send': {'zh': '发送', 'en': 'Send'},
    'attach_file': {'zh': '附加文件', 'en': 'Attach file'},
  };

  /// 获取翻译文本 - 简单粗暴的逻辑
  String translate(String key) {
    final translations = _localizedValues[key];
    if (translations == null) {
      // 开发时能立即发现缺失的key
      return '!$key!';
    }

    // 核心逻辑：是zh就zh，否则en，没有复杂判断
    final languageCode = locale.languageCode;
    if (languageCode == 'zh') {
      return translations['zh'] ?? translations['en'] ?? key;
    }
    // 所有非中文的都fallback到英文
    return translations['en'] ?? key;
  }

  // 便捷访问器 - 代码里直接用更清晰
  String get settings => translate('settings');
  String get version => translate('version');
  String get ok => translate('ok');
  
  String get serverIp => translate('server_ip');
  String get port => translate('port');
  String get username => translate('username');
  String get connect => translate('connect');
  String get fillAllFields => translate('fill_all_fields');
  String get connectionFailed => translate('connection_failed');
  
  String get theme => translate('theme');
  String get themeDark => translate('theme_dark');
  String get themeLight => translate('theme_light');
  String get language => translate('language');
  
  String get chat => translate('chat');
  String get typeMessage => translate('type_message');
  String get send => translate('send');
  String get attachFile => translate('attach_file');
}

/// LocalizationsDelegate - Flutter要求的接口
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // 只支持zh和en，其他的都算支持但会fallback到en
    return true;
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // 同步返回，没有异步加载的复杂性
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
