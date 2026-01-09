/// 应用常量 - 单一数据源
class AppConstants {
  // 版本信息
  static const String version = '2.2.0';
  static const String buildNumber = '220';
  static const String appName = 'TouchFishAstra';
  static const String author = 'ILoveScratch2';

  // 项目信息
  static const String description =
      'A modern, cross-platform TouchFish client built with Flutter(supported TouchFish V4 protocol).\n\nTouchFishAstra is Copyleft free software: you are free to use, study, share, and improve it at any time.';
  static const String descriptionZh = '基于 Flutter 构建的现代化跨平台 TouchFish 客户端（已适配TouchFish V4 协议）\n\nTouchFishAstra 是 Copyleft 的自由软件:您可以随时使用、研究共享和改进它。';
  static const String githubUrl =
      'https://github.com/ILoveScratch2/TouchFishAstra';
  static const String license = 'Copyright (c) 2025 ILoveScratch2. Licensed under AGPL-3.0 License.';

  // 字体版权声明
  static const String fontLicenseZh = '''本应用使用 华为 HarmonyOS Sans 字体。
Copyright 2021 华为终端有限公司
HarmonyOS Sans 字体软件受 HarmonyOS Sans 字体许可协议保护''';

  static const String fontLicenseEn = '''This application uses the HUAWEI HarmonyOS Sans fonts.
Copyright 2021 Huawei Device Co., Ltd.
HarmonyOS Sans Fonts Software is licensed under the HarmonyOS Sans Fonts License Agreement.''';

  // 2025->2026 春节主题
  // 春节时间验证
  static bool get springFestivalThemeEnabled {
    final now = DateTime.now();
    final startDate = DateTime(2026, 2, 15);
    final endDate = DateTime(2026, 2, 23, 23, 59, 59);
    return now.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
           now.isBefore(endDate.add(const Duration(seconds: 1)));
  }
  
  static const List<String> springFestivalGreetings = [
    'TFA 在春节提示您： 新春快乐！',
    'TFA 在春节提示您： 恭喜发财！',
    'TFA 在春节提示您： 马年大吉！',
    'TFA 在春节提示您： 万事如意！',
    'TFA 在春节提示您： 阖家欢乐！',
    'TFA 在春节提示您： 年年有余！',
    'TFA 在春节提示您： 福星高照！',
    'TFA 在春节提示您： 吉祥如意！',
  ];
  static const List<String> springFestivalChars = ['骏马追风传讯去', '马上聊到', '吉羊接福TF来'];
}
