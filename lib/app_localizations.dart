import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// 静态访问，这样每个Widget都能方便获取
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    // App通用
    'settings': {'zh': '设置', 'en': 'Settings'},
    'admin': {'zh': '管理员', 'en': 'Admin'},
    'version': {'zh': '版本', 'en': 'Version'},
    'ok': {'zh': '确定', 'en': 'OK'},

    // 连接界面
    'server_ip': {'zh': '服务器IP', 'en': 'Server IP'},
    'port': {'zh': '端口', 'en': 'Port'},
    'username': {'zh': '用户名', 'en': 'Username'},
    'connect': {'zh': '连接', 'en': 'Connect'},
    'fill_all_fields': {'zh': '请填写所有字段', 'en': 'Fill all fields'},
    'connection_failed': {'zh': '连接失败', 'en': 'Connection failed'},
    'remember_config': {'zh': '记住配置', 'en': 'Remember Configuration'},

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

    // 文件传输
    'user_joined': {'zh': '用户 {0} 加入聊天室。', 'en': 'User {0} joined the chat.'},
    'file_received': {
      'zh': '[文件传输] 文件接收完成: {0} (未自动保存)',
      'en': '[File Transfer] File received: {0} (not auto-saved)',
    },
    'file_size_mismatch': {
      'zh': '[文件传输] 警告: 文件大小不匹配',
      'en': '[File Transfer] Warning: File size mismatch',
    },
    'cannot_create_dir': {
      'zh': '[文件传输] 无法创建下载目录: {0}',
      'en': '[File Transfer] Cannot create download directory: {0}',
    },
    'cannot_get_dir': {
      'zh': '[文件传输] 无法获取下载目录',
      'en': '[File Transfer] Cannot get download directory',
    },
    'file_saved': {
      'zh': '[文件传输] 文件已保存: {0}',
      'en': '[File Transfer] File saved: {0}',
    },
    'file_save_failed': {
      'zh': '[文件传输] 保存失败: {0}',
      'en': '[File Transfer] Save failed: {0}',
    },
    'receiving_file': {
      'zh': '[文件传输] 正在接收文件: {0}',
      'en': '[File Transfer] Receiving file: {0}',
    },

    // 连接状态
    'disconnected_from_server': {
      'zh': '与服务器的连接已断开',
      'en': 'Disconnected from server',
    },
    'connection_lost': {'zh': '连接已断开', 'en': 'Connection Lost'},

    // 文件对话框
    'file_saved_title': {'zh': '文件已保存', 'en': 'File Saved'},
    'file_location': {'zh': '文件位置:', 'en': 'File Location:'},
    'file_location_hint': {
      'zh': '提示: 您可以在文件管理器中找到此文件',
      'en': 'Hint: You can find this file in the file manager',
    },
    'close': {'zh': '关闭', 'en': 'Close'},
    'open_file': {'zh': '打开文件', 'en': 'Open File'},
    'cannot_open_file': {
      'zh': '无法打开文件，请在文件管理器中查找',
      'en': 'Cannot open file, please find it in the file manager',
    },
    'open_failed': {'zh': '打开失败: {0}', 'en': 'Open failed: {0}'},
    'cannot_open_location': {
      'zh': '无法打开文件位置: {0}',
      'en': 'Cannot open file location: {0}',
    },

    // 设置界面
    'cancel': {'zh': '取消', 'en': 'Cancel'},
    'chat_settings': {'zh': '聊天设置', 'en': 'Chat Settings'},
    'chat_view_mode': {'zh': '聊天界面模式', 'en': 'Chat View Mode'},
    'bubble_mode': {'zh': '气泡模式', 'en': 'Bubble Mode'},
    'list_mode': {'zh': '列表模式', 'en': 'List Mode'},
    'bubble': {'zh': '气泡', 'en': 'Bubble'},
    'list': {'zh': '列表', 'en': 'List'},
    'auto_save_files': {'zh': '自动保存接收的文件', 'en': 'Auto-save received files'},
    'auto_save_hint': {
      'zh': '文件将保存到指定文件夹',
      'en': 'Files will be saved to the specified folder',
    },
    'download_path': {'zh': '下载保存路径', 'en': 'Download Path'},
    'default_folder': {'zh': '使用默认下载文件夹', 'en': 'Use default download folder'},
    'reset_default': {'zh': '重置为默认', 'en': 'Reset to default'},
    'select_folder': {'zh': '选择文件夹', 'en': 'Select Folder'},
    'color_settings': {'zh': '聊天颜色设置', 'en': 'Chat Color Settings'},
    'my_bubble_color': {'zh': '我的消息气泡颜色', 'en': 'My Message Bubble Color'},
    'other_bubble_color': {
      'zh': '对方消息气泡颜色',
      'en': 'Other Message Bubble Color',
    },
    'system_msg_color': {
      'zh': '系统消息/公告颜色',
      'en': 'System Message/Announcement Color',
    },
    'ban_color': {'zh': '封禁提醒颜色', 'en': 'Ban Notification Color'},
    'pick_my_color': {'zh': '选择我的消息颜色', 'en': 'Pick My Message Color'},
    'pick_other_color': {'zh': '选择对方消息颜色', 'en': 'Pick Other Message Color'},
    'pick_system_color': {'zh': '选择系统消息颜色', 'en': 'Pick System Message Color'},
    'pick_ban_color': {'zh': '选择封禁提醒颜色', 'en': 'Pick Ban Notification Color'},
    'markdown_rendering': {
      'zh': 'Markdown/LaTeX渲染',
      'en': 'Markdown/LaTeX Rendering',
    },
    'markdown_hint': {
      'zh': '启用后将渲染消息中的Markdown和LaTeX公式',
      'en': 'Render Markdown and LaTeX formulas in messages',
    },
    'enter_to_send': {'zh': 'Enter键发送消息', 'en': 'Enter to Send'},
    'enter_to_send_hint': {
      'zh': '开启时按Enter发送(单行输入);关闭时支持多行输入',
      'en':
          'When enabled, press Enter to send (single line); when disabled, multiline input',
    },
    'auto_scroll': {'zh': '自动滚动到最新消息', 'en': 'Auto-scroll to Latest'},
    'auto_scroll_hint': {
      'zh': '开启后有新消息总是滚动到底部',
      'en': 'When enabled, always scroll to bottom on new messages',
    },
    'enable_notifications': {'zh': '启用消息通知', 'en': 'Enable Notifications'},
    'notifications_hint': {
      'zh': '收到新消息时显示系统通知',
      'en': 'Show system notifications for new messages',
    },
    'disconnect_from_server': {'zh': '断开与服务器的连接', 'en': 'Disconnect from Server'},
    'confirm_disconnect': {
      'zh': '确认断开连接',
      'en': 'Confirm Disconnect',
    },
    'confirm_disconnect_message': {
      'zh': '确定要断开与服务器的连接吗？',
      'en': 'Are you sure you want to disconnect from the server?',
    },
    'disconnect': {'zh': '断开连接', 'en': 'Disconnect'},

    // 管理员功能
    'admin_broadcast': {'zh': '广播消息', 'en': 'Broadcast Message'},
    'admin_broadcast_hint': {
      'zh': '输入要广播的消息内容',
      'en': 'Enter message to broadcast',
    },
    'admin_ban': {'zh': '封禁用户', 'en': 'Ban User'},
    'admin_ban_hint': {'zh': '输入要封禁的IP', 'en': 'Enter IP to ban'},
    'admin_enable': {'zh': '解封用户', 'en': 'Unban User'},
    'admin_enable_hint': {'zh': '输入要解封的IP', 'en': 'Enter IP to unban'},
    'admin_set': {'zh': '设置配置', 'en': 'Set Configuration'},
    'admin_set_hint': {
      'zh': '输入配置项和值 (格式: key value)',
      'en': 'Enter config key and value (format: key value)',
    },
    'admin_accept': {'zh': '接受加入请求', 'en': 'Accept Join Request'},
    'admin_accept_hint': {'zh': '输入要接受的请求', 'en': 'Enter request to accept'},
    'admin_reject': {'zh': '拒绝加入请求', 'en': 'Reject Join Request'},
    'admin_reject_hint': {'zh': '输入要拒绝的请求', 'en': 'Enter request to reject'},
    'admin_search': {'zh': '搜索用户', 'en': 'Search User'},
    'admin_search_hint': {'zh': '输入搜索内容', 'en': 'Enter content to search'},
    'admin_req': {'zh': '查看加入请求', 'en': 'View Join Requests'},
    'admin_req_hint': {
      'zh': '查看所有待处理的加入请求',
      'en': 'View all pending join requests',
    },
    'admin_execute': {'zh': '执行', 'en': 'Execute'},
    'admin_results': {'zh': '执行结果', 'en': 'Results'},
    'admin_clear': {'zh': '清空', 'en': 'Clear'},
    'admin_connect_title': {'zh': '连接管理员控制台', 'en': 'Connect to Admin Console'},
    'admin_connect_hint': {
      'zh': '请输入服务器管理员端口\n服务端执行 "admin on" 后会显示',
      'en': 'Enter admin port\nShown after server executes "admin on"',
    },
    'admin_port': {'zh': '管理员端口', 'en': 'Admin Port'},
    'admin_connect_button': {'zh': '连接管理员控制台', 'en': 'Connect to Admin'},
    'admin_connecting': {'zh': '连接中...', 'en': 'Connecting...'},
    'admin_connected': {'zh': '管理员连接成功', 'en': 'Admin connected'},
    'admin_connect_failed': {
      'zh': '连接失败：无权限或端口错误',
      'en': 'Connection failed: unauthorized or invalid port',
    },
    'admin_unauthorized': {
      'zh':
          '无管理员权限或端口错误\n请检查：1. 服务端是否执行了 "admin on"\n2. 端口号是否正确\n3. 您的IP是否在管理员列表',
      'en':
          'Unauthorized or invalid port\nCheck: 1. Server executed "admin on"\n2. Port number is correct\n3. Your IP is in admin list',
    },
    'admin_status_connected': {
      'zh': '已连接到管理员控制台',
      'en': 'Connected to Admin Console',
    },
    'admin_disconnect': {'zh': '断开', 'en': 'Disconnect'},
    'admin_removed': {
      'zh': '您已被移除管理员列表',
      'en': 'You have been removed from admin list',
    },
    'admin_server_closed': {'zh': '服务器已关闭', 'en': 'Server closed'},
    'admin_invalid_port': {'zh': '无效的端口号', 'en': 'Invalid port number'},
    'admin_search_type': {'zh': '搜索类型', 'en': 'Search Type'},
    'admin_search_param_hint': {
      'zh': '输入搜索参数（用户名/IP）',
      'en': 'Enter search parameter (username/IP)',
    },
    'admin_search_times_hint': {
      'zh': '输入最小发送次数',
      'en': 'Enter minimum send times',
    },
    'admin_set_option': {'zh': '配置选项', 'en': 'Configuration Option'},
    
    // 导出聊天记录
    'export_chat_history': {'zh': '导出聊天记录', 'en': 'Export Chat History'},
    'export_chat_hint': {
      'zh': '导出当前会话的所有消息为TXT文件',
      'en': 'Export all messages of current session to TXT file',
    },
    'export_success': {'zh': '导出成功', 'en': 'Export Success'},
    'export_failed': {'zh': '导出失败', 'en': 'Export Failed'},
    'exported_to': {'zh': '已导出到: {0}', 'en': 'Exported to: {0}'},
    'no_messages_to_export': {
      'zh': '当前会话没有消息可导出',
      'en': 'No messages to export in current session',
    },
  };

  String translate(String key, [List<String> args = const []]) {
    final translations = _localizedValues[key];
    if (translations == null) {
      return '!$key!';
    }

    final languageCode = locale.languageCode;
    var text = languageCode == 'zh'
        ? (translations['zh'] ?? translations['en'] ?? key)
        : (translations['en'] ?? key);
    for (var i = 0; i < args.length; i++) {
      text = text.replaceAll('{$i}', args[i]);
    }
    return text;
  }

  // 便捷访问器
  String get settings => translate('settings');
  String get admin => translate('admin');
  String get version => translate('version');
  String get ok => translate('ok');

  String get serverIp => translate('server_ip');
  String get port => translate('port');
  String get username => translate('username');
  String get connect => translate('connect');
  String get fillAllFields => translate('fill_all_fields');
  String get connectionFailed => translate('connection_failed');
  String get rememberConfig => translate('remember_config');

  String get theme => translate('theme');
  String get themeDark => translate('theme_dark');
  String get themeLight => translate('theme_light');
  String get language => translate('language');

  String get chat => translate('chat');
  String get typeMessage => translate('type_message');
  String get send => translate('send');
  String get attachFile => translate('attach_file');

  // 文件传输
  String userJoined(String username) => translate('user_joined', [username]);
  String fileReceived(String filename) =>
      translate('file_received', [filename]);
  String get fileSizeMismatch => translate('file_size_mismatch');
  String cannotCreateDir(String error) =>
      translate('cannot_create_dir', [error]);
  String get cannotGetDir => translate('cannot_get_dir');
  String fileSaved(String path) => translate('file_saved', [path]);
  String fileSaveFailed(String error) => translate('file_save_failed', [error]);
  String receivingFile(String filename) =>
      translate('receiving_file', [filename]);

  // 连接状态
  String get disconnectedFromServer => translate('disconnected_from_server');
  String get connectionLost => translate('connection_lost');

  // 文件对话框
  String get fileSavedTitle => translate('file_saved_title');
  String get fileLocation => translate('file_location');
  String get fileLocationHint => translate('file_location_hint');
  String get close => translate('close');
  String get openFile => translate('open_file');
  String get cannotOpenFile => translate('cannot_open_file');
  String openFailed(String error) => translate('open_failed', [error]);
  String cannotOpenLocation(String error) =>
      translate('cannot_open_location', [error]);

  // 设置界面
  String get cancel => translate('cancel');
  String get chatSettings => translate('chat_settings');
  String get chatViewMode => translate('chat_view_mode');
  String get bubbleMode => translate('bubble_mode');
  String get listMode => translate('list_mode');
  String get bubble => translate('bubble');
  String get list => translate('list');
  String get autoSaveFiles => translate('auto_save_files');
  String get autoSaveHint => translate('auto_save_hint');
  String get downloadPath => translate('download_path');
  String get defaultFolder => translate('default_folder');
  String get resetDefault => translate('reset_default');
  String get selectFolder => translate('select_folder');
  String get colorSettings => translate('color_settings');
  String get myBubbleColor => translate('my_bubble_color');
  String get otherBubbleColor => translate('other_bubble_color');
  String get systemMsgColor => translate('system_msg_color');
  String get banColor => translate('ban_color');
  String get pickMyColor => translate('pick_my_color');
  String get pickOtherColor => translate('pick_other_color');
  String get pickSystemColor => translate('pick_system_color');
  String get pickBanColor => translate('pick_ban_color');
  String get markdownRendering => translate('markdown_rendering');
  String get markdownHint => translate('markdown_hint');
  String get enterToSend => translate('enter_to_send');
  String get enterToSendHint => translate('enter_to_send_hint');
  String get autoScroll => translate('auto_scroll');
  String get autoScrollHint => translate('auto_scroll_hint');
  String get enableNotifications => translate('enable_notifications');
  String get notificationsHint => translate('notifications_hint');
  String get disconnectFromServer => translate('disconnect_from_server');
  String get confirmDisconnect => translate('confirm_disconnect');
  String get confirmDisconnectMessage => translate('confirm_disconnect_message');
  String get disconnect => translate('disconnect');

  // 导出聊天记录
  String get exportChatHistory => translate('export_chat_history');
  String get exportChatHint => translate('export_chat_hint');
  String get exportSuccess => translate('export_success');
  String get exportFailed => translate('export_failed');
  String exportedTo(String path) => translate('exported_to', [path]);
  String get noMessagesToExport => translate('no_messages_to_export');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return true;
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
