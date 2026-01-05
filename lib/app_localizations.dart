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
    
    // 上下文菜单
    'context_cut': {'zh': '剪切', 'en': 'Cut'},
    'context_copy': {'zh': '复制', 'en': 'Copy'},
    'context_paste': {'zh': '粘贴', 'en': 'Paste'},
    'context_format': {'zh': '格式', 'en': 'Format'},
    'context_bold': {'zh': '加粗', 'en': 'Bold'},
    'context_italic': {'zh': '斜体', 'en': 'Italic'},
    'context_strikethrough': {'zh': '删除线', 'en': 'Strikethrough'},

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

    // 2026 春节主题
    'spring_festival_greeting': {'zh': '新春快乐，万事如意！', 'en': 'Happy Spring Festival!'},
    'spring_festival_welcome': {'zh': '欢迎来到TouchFishAstra春节版！', 'en': 'Welcome to TouchFishAstra Spring Festival Edition!'},
    'spring_festival_wishes': {'zh': '马年大吉，恭喜发财！', 'en': 'Good fortune in the Year of the Horse!'},
    'open_failed': {'zh': '打开失败: {0}', 'en': 'Open failed: {0}'},
    'cannot_open_location': {
      'zh': '无法打开文件位置: {0}',
      'en': 'Cannot open file location: {0}',
    },

    // 设置界面
    'cancel': {'zh': '取消', 'en': 'Cancel'},
    'chat_settings': {'zh': '聊天设置', 'en': 'Chat Settings'},
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
    'server_announcement_color': {'zh': '服务器公告颜色', 'en': 'Server Announcement Color'},
    'other_private_color': {'zh': '对方私聊颜色', 'en': 'Other Private Message Color'},
    'my_private_color': {'zh': '我的私聊颜色', 'en': 'My Private Message Color'},
    'pick_my_color': {'zh': '选择我的消息颜色', 'en': 'Pick My Message Color'},
    'pick_other_color': {'zh': '选择对方消息颜色', 'en': 'Pick Other Message Color'},
    'pick_system_color': {'zh': '选择系统消息颜色', 'en': 'Pick System Message Color'},
    'pick_server_announcement_color': {'zh': '选择服务器公告颜色', 'en': 'Pick Server Announcement Color'},
    'pick_other_private_color': {'zh': '选择对方私聊颜色', 'en': 'Pick Other Private Message Color'},
    'pick_my_private_color': {'zh': '选择我的私聊颜色', 'en': 'Pick My Private Message Color'},
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
      'zh': '接收新消息时显示系统通知',
      'en': 'Show system notifications for new messages',
    },
    'load_chat_history': {'zh': '恢复聊天历史', 'en': 'Load Chat History'},
    'load_chat_history_hint': {
      'zh': '连接时自动加载上线前的公共聊天记录',
      'en': 'Auto-load public chat history from before connection',
    },
    'history_separator': {'zh': '以上为历史消息', 'en': 'Above are historical messages'},
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
    'admin_ban': {'zh': '封禁', 'en': 'Ban'},
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
      'zh': '无管理员权限',
      'en': 'Unauthorized - Admin Permission Required',
    },
    'admin_need_permission': {
      'zh': '您需要Admin或Root权限才能使用管理员功能',
      'en': 'You need Admin or Root permission to use admin features',
    },
    'admin_pending_requests': {
      'zh': '待审核用户',
      'en': 'Pending Requests',
    },
    'admin_online_users': {
      'zh': '在线用户',
      'en': 'Online Users',
    },
    'admin_no_online_users': {
      'zh': '暂无其他在线用户',
      'en': 'No other online users',
    },
    'admin_kick': {
      'zh': '踢出',
      'en': 'Kick',
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
    'admin_actions': {'zh': '管理操作', 'en': 'Admin Actions'},
    'admin_broadcast_sent': {'zh': '广播消息已发送', 'en': 'Broadcast sent'},
    'admin_config': {'zh': '服务器配置', 'en': 'Server Configuration'},
    'admin_config_key': {'zh': '配置项', 'en': 'Config Key'},
    'admin_config_value': {'zh': '配置值', 'en': 'Config Value'},
    'admin_config_updated': {'zh': '配置已更新', 'en': 'Config updated'},
    'admin_ban_added': {'zh': '封禁已添加', 'en': 'Ban added'},
    'admin_unban': {'zh': '解除封禁', 'en': 'Unban'},
    'admin_unban_success': {'zh': '解封成功', 'en': 'Unban successful'},
    'update': {'zh': '更新', 'en': 'Update'},
    'broadcast': {'zh': '广播', 'en': 'Broadcast'},
    'config': {'zh': '配置', 'en': 'Config'},
    'ban': {'zh': '封禁', 'en': 'Ban'},
    'unban': {'zh': '解封', 'en': 'Unban'},
    'words': {'zh': '词汇', 'en': 'Words'},
    'banned_word': {'zh': '敏感词', 'en': 'Banned Word'},
    'no_banned_items': {'zh': '没有封禁项', 'en': 'No banned items'},
    'accept': {'zh': '接受', 'en': 'Accept'},
    'reject': {'zh': '拒绝', 'en': 'Reject'},
    'kick': {'zh': '踢出', 'en': 'Kick'},
    'confirm_kick_title': {'zh': '确认踢出', 'en': 'Confirm Kick'},
    'confirm_kick_message': {'zh': '确定要踢出用户 UID: {0} 吗？', 'en': 'Are you sure you want to kick user UID: {0}?'},
    'kicked_user': {'zh': '已踢出用户 UID: {0}', 'en': 'Kicked user UID: {0}'},
    
    // 彩蛋
    'easter_egg_quote_1': {'zh': 'TouchFish 不是让你摸鱼', 'en': 'TouchFish is not for slacking off'},
    'easter_egg_quote_2': {'zh': '水题也可以用 TouchFish Touch-Fish', 'en': 'Even water questions can use TouchFish slack-off'},
    'easter_egg_quote_3': {'zh': 'TouchFish 的作者是XSFX', 'en': 'The author of TouchFish is XSFX'},
    'easter_egg_quote_4': {'zh': 'TouchFish v4！', 'en': 'TouchFish v4!'},
    'easter_egg_quote_5': {'zh': 'Luogu 是个好地方', 'en': 'Luogu is a good place'},
    'easter_egg_quote_6': {'zh': '你好中国！', 'en': 'Hello China!'},
    'easter_egg_quote_7': {'zh': 'TouchFish 让生活更美好', 'en': 'TouchFish makes life better'},
    'easter_egg_quote_8': {'zh': 'TouchFish Astra支持Android！', 'en': 'TouchFish Astra supports Android!'},
    'easter_egg_quote_9': {'zh': '台湾及其附属岛屿自古以来就是中国不可分割的神圣领土，坚持一个中国原则不动摇是最基本的。任何外部势力以及反动分子最终只会被历史唾弃。台湾回归是不可逆转，不可停止的历史进程', 'en': 'Taiwan and its affiliated islands have been an inseparable part of China\'s sacred territory since ancient times. Adhering to the one-China principle is unwavering and fundamental. Any external forces and reactionaries will ultimately be condemned by history. The reunification of Taiwan is an irreversible and unstoppable historical process.'},
    'easter_egg_quote_10': {'zh': 'TouchFish 让你成为摸鱼界的传奇！ ', 'en': 'Congratulations on becoming a legend by TouchFish! '},
    
    // 彩蛋
    'easter_egg_level_1': {'zh': 'TouchFisher 等级 1 (LTS)', 'en': 'TouchFisher Level 1 (LTS)'},
    'easter_egg_level_2': {'zh': 'TouchFisher 等级 2 (Pro)', 'en': 'TouchFisher Level 2 (Pro)'},
    'easter_egg_level_3': {'zh': 'TouchFisher 等级 3 (Plus)', 'en': 'TouchFisher Level 3 (Plus)'},
    'easter_egg_level_4': {'zh': 'TouchFisher 等级 4 (逝去的Mobile)', 'en': 'TouchFisher Level 4 (LEGACY Mobile)'},
    'easter_egg_level_5': {'zh': 'TouchFisher 等级 5 (TouchFish UI Remake)', 'en': 'TouchFisher Level 5 (TouchFish UI Remake)'},
    'easter_egg_level_6': {'zh': 'TouchFisher 等级 6 (TouchFish Astra)', 'en': 'TouchFisher Level 6 (TouchFish Astra)'},
    'easter_egg_level_7': {'zh': 'TouchFisher 等级 7 (XSFX 版本) 猜猜是谁', 'en': 'TouchFisher Level 7 (XSFX Edition) Guess Who'},
    'easter_egg_achievement': {'zh': '达成成就：{0}！', 'en': 'Achievement Unlocked: {0}!'},
    'easter_egg_tap_count': {'zh': 'TouchFish次数：{0}', 'en': 'TouchFish Count: {0}'},
    
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
    'join_request': {'zh': '加入请求', 'en': 'Join Request'},
    'status_change': {'zh': '状态变更', 'en': 'Status Change'},
    'config_change': {'zh': '配置变更', 'en': 'Config Change'},
    'system': {'zh': '系统', 'en': 'System'},
    
    // 文件消息 i18n
    'click_to_save_file': {'zh': '点击保存文件', 'en': 'Click to save file'},
    'file_saved_to': {'zh': '文件已保存到: {0}', 'en': 'File saved to: {0}'},
    'save_failed': {'zh': '保存失败: {0}', 'en': 'Save failed: {0}'},
    'cannot_get_download_dir': {'zh': '无法获取下载目录', 'en': 'Cannot get download directory'},
    
    // 私聊功能 i18n
    'select_chat_target': {'zh': '选择聊天对象', 'en': 'Select Chat Target'},
    'public_chat': {'zh': '公共聊天', 'en': 'Public Chat'},
    'private_chat': {'zh': '私聊', 'en': 'Private Chat'},
    'private_chat_to': {'zh': '私聊给 {0}', 'en': 'Private chat to {0}'},
    
    // 服务器消息 i18n
    'server_started': {'zh': '服务器已启动', 'en': 'Server started'},
    'server_stopped': {'zh': '服务器已停止', 'en': 'Server stopped'},
    'server_version_label': {'zh': '版本', 'en': 'Version'},
    'time_label': {'zh': '时间', 'en': 'Time'},
    'server_response': {'zh': '服务器响应', 'en': 'Server response'},
    'server_review_accepted': {'zh': '服务器审核通过', 'en': 'Server review accepted'},
    'server_review_rejected': {'zh': '服务器审核拒绝', 'en': 'Server review rejected'},
    'review_accepted': {'zh': '{0} 通过了您的加入申请', 'en': '{0} accepted your request'},
    'review_rejected': {'zh': '{0} 拒绝了您的加入申请', 'en': '{0} rejected your request'},
    
    // 加入状态 i18n
    'join_accepted': {'zh': '加入成功', 'en': 'Join accepted'},
    'join_pending': {'zh': '等待管理员审核', 'en': 'Pending admin review'},
    'join_ip_banned': {'zh': 'IP被封禁', 'en': 'IP banned'},
    'join_room_full': {'zh': '房间已满', 'en': 'Room full'},
    'join_username_duplicate': {'zh': '用户名重复', 'en': 'Username duplicate'},
    'join_banned_words': {'zh': '用户名含违禁词', 'en': 'Username contains banned words'},
    
    // 用户状态 i18n
    'status_rejected': {'zh': '被拒绝', 'en': 'Rejected'},
    'status_kicked': {'zh': '被踢出', 'en': 'Kicked'},
    'status_offline': {'zh': '离线', 'en': 'Offline'},
    'status_pending': {'zh': '等待中', 'en': 'Pending'},
    'status_online': {'zh': '在线', 'en': 'Online'},
    'status_admin': {'zh': '管理员', 'en': 'Admin'},
    'status_root': {'zh': '超级管理员', 'en': 'Root'},
    
    // 消息类型 i18n  
    'broadcast_prefix': {'zh': '{0} 公告', 'en': '{0} Broadcast'},
    'request_join_msg': {'zh': '{0} (UID: {1}) 请求加入: {2}', 'en': '{0} (UID: {1}) requested to join: {2}'},
    'status_changed_msg': {'zh': '{0} (UID: {1}) 状态变更为: {2}', 'en': '{0} (UID: {1}) status changed to: {2}'},
    'config_changed_msg': {'zh': '配置项 {0} 变更为: {1}', 'en': 'Config {0} changed to: {1}'},
    
    // 服务器信息对话框
    'server_info': {'zh': '服务器信息', 'en': 'Server Information'},
    'my_uid': {'zh': '我的UID', 'en': 'My UID'},
    'user_list': {'zh': '用户列表', 'en': 'User List'},
    'uid': {'zh': 'UID', 'en': 'UID'},
    'status': {'zh': '状态', 'en': 'Status'},
    'online_users': {'zh': '在线用户', 'en': 'Online Users'},
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
  
  // 上下文菜单
  String get contextCut => translate('context_cut');
  String get contextCopy => translate('context_copy');
  String get contextPaste => translate('context_paste');
  String get contextFormat => translate('context_format');
  String get contextBold => translate('context_bold');
  String get contextItalic => translate('context_italic');
  String get contextStrikethrough => translate('context_strikethrough');

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
  String get serverAnnouncementColor => translate('server_announcement_color');
  String get pickMyColor => translate('pick_my_color');
  String get pickOtherColor => translate('pick_other_color');
  String get pickSystemColor => translate('pick_system_color');
  String get pickServerAnnouncementColor => translate('pick_server_announcement_color');
  String get otherPrivateColor => translate('other_private_color');
  String get myPrivateColor => translate('my_private_color');
  String get pickOtherPrivateColor => translate('pick_other_private_color');
  String get pickMyPrivateColor => translate('pick_my_private_color');
  String get markdownRendering => translate('markdown_rendering');
  String get markdownHint => translate('markdown_hint');
  String get enterToSend => translate('enter_to_send');
  String get enterToSendHint => translate('enter_to_send_hint');
  String get autoScroll => translate('auto_scroll');
  String get autoScrollHint => translate('auto_scroll_hint');
  String get enableNotifications => translate('enable_notifications');
  String get notificationsHint => translate('notifications_hint');
  String get loadChatHistory => translate('load_chat_history');
  String get loadChatHistoryHint => translate('load_chat_history_hint');
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
  
  // 文件消息
  String get clickToSaveFile => translate('click_to_save_file');
  String fileSavedTo(String path) => translate('file_saved_to', [path]);
  String saveFailed(String error) => translate('save_failed', [error]);
  String get cannotGetDownloadDir => translate('cannot_get_download_dir');
  
  // 私聊功能
  String get selectChatTarget => translate('select_chat_target');
  String get publicChat => translate('public_chat');
  String get privateChat => translate('private_chat');
  String privateChatTo(String target) => translate('private_chat_to', [target]);
  
  // 服务器消息
  String get serverStarted => translate('server_started');
  String get serverStopped => translate('server_stopped');
  String get serverVersionLabel => translate('server_version_label');
  String get timeLabel => translate('time_label');
  String get serverResponse => translate('server_response');
  String reviewAccepted(String operator) => translate('review_accepted', [operator]);
  String reviewRejected(String operator) => translate('review_rejected', [operator]);
  
  // 加入状态
  String get joinAccepted => translate('join_accepted');
  String get joinPending => translate('join_pending');
  String get joinIpBanned => translate('join_ip_banned');
  String get joinRoomFull => translate('join_room_full');
  String get joinUsernameDuplicate => translate('join_username_duplicate');
  String get joinBannedWords => translate('join_banned_words');
  
  // 用户状态
  String get statusRejected => translate('status_rejected');
  String get statusKicked => translate('status_kicked');
  String get statusOffline => translate('status_offline');
  String get statusPending => translate('status_pending');
  String get statusOnline => translate('status_online');
  String get statusAdmin => translate('status_admin');
  String get statusRoot => translate('status_root');
  
  // 历史消息分隔符
  String get historySeparator => translate('history_separator');
  
  // 消息类型
  String broadcastPrefix(String sender) => translate('broadcast_prefix', [sender]);
  String requestJoinMsg(String username, String uid, String result) => translate('request_join_msg', [username, uid, result]);
  String statusChangedMsg(String username, String uid, String status) => translate('status_changed_msg', [username, uid, status]);
  String configChangedMsg(String key, String value) => translate('config_changed_msg', [key, value]);
  
  // 服务器信息
  String get serverInfo => translate('server_info');
  String get myUid => translate('my_uid');
  String get userList => translate('user_list');
  String get uid => translate('uid');
  String get status => translate('status');
  
  // Confirm Kick 对话框
  String get confirmKickTitle => translate('confirm_kick_title');
  String confirmKickMessage(String uid) => translate('confirm_kick_message', [uid]);
  String kickedUser(String uid) => translate('kicked_user', [uid]);
  String get kick => translate('kick');
  
  // 彩蛋 （被你发现了！）
  String get easterEggQuote1 => translate('easter_egg_quote_1');
  String get easterEggQuote2 => translate('easter_egg_quote_2');
  String get easterEggQuote3 => translate('easter_egg_quote_3');
  String get easterEggQuote4 => translate('easter_egg_quote_4');
  String get easterEggQuote5 => translate('easter_egg_quote_5');
  String get easterEggQuote6 => translate('easter_egg_quote_6');
  String get easterEggQuote7 => translate('easter_egg_quote_7');
  String get easterEggQuote8 => translate('easter_egg_quote_8');
  String get easterEggQuote9 => translate('easter_egg_quote_9');
  String get easterEggQuote10 => translate('easter_egg_quote_10');
  String get easterEggLevel1 => translate('easter_egg_level_1');
  String get easterEggLevel2 => translate('easter_egg_level_2');
  String get easterEggLevel3 => translate('easter_egg_level_3');
  String get easterEggLevel4 => translate('easter_egg_level_4');
  String get easterEggLevel5 => translate('easter_egg_level_5');
  String get easterEggLevel6 => translate('easter_egg_level_6');
  String get easterEggLevel7 => translate('easter_egg_level_7');
  String easterEggAchievement(String level) => translate('easter_egg_achievement', [level]);
  String easterEggTapCount(String count) => translate('easter_egg_tap_count', [count]);
  
  // 春节主题
  String get springFestivalGreeting => translate('spring_festival_greeting');
  String get springFestivalWelcome => translate('spring_festival_welcome');
  String get springFestivalWishes => translate('spring_festival_wishes');
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
