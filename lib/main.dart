import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'socket_service.dart';
import 'main_navigation.dart';
import 'settings_screen.dart';
import 'app_localizations.dart';
import 'constants.dart';
import 'notification_service.dart';

void main() async {
  print('Welcome to TouchFishAstra! ');
  print('欢迎使用 TouchFishAstra！ ');
  print('恭喜你发现了彩蛋！ ');
  print('打个广告：https://github.com/ILoveScratch2/ClipNote.git');
  print('如果你喜欢TouchFishAstra项目，欢迎给Star！');
  print('如果你有任何建议或想法，欢迎提交Issue或PR！');
  print('作者：ILoveScratch2(YWD2023)   版权所有，使用GNU AGPL v3许可协议！');
  print('其实……还有一个彩蛋哦（Tips：尝试点击应用“关于”页面的标题哦）');
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const TouchFishAstra());
}

class TouchFishAstra extends StatefulWidget {
  const TouchFishAstra({super.key});

  @override
  State<TouchFishAstra> createState() => _TouchFishAstraState();
}

class _TouchFishAstraState extends State<TouchFishAstra> {
  var _themeMode = ThemeMode.system;
  var _locale = const Locale('zh');
  SocketService? _socket;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _onConnected(SocketService socket, String username) {
    socket.connectionStatus.listen((connected) {
      if (!connected && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _socket?.dispose();
              _socket = null;
              _username = null;
            });
          }
        });
      }
    });

    setState(() {
      _socket = socket;
      _username = username;
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme_mode') ?? 'system';
    final lang = prefs.getString('language') ?? 'zh';

    setState(() {
      _themeMode = theme == 'dark'
          ? ThemeMode.dark
          : theme == 'light'
          ? ThemeMode.light
          : ThemeMode.system;
      _locale = Locale(lang);
    });
  }

  Future<void> _toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      newMode == ThemeMode.dark ? 'dark' : 'light',
    );

    setState(() {
      _themeMode = newMode;
    });
  }

  Future<void> _changeLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);

    setState(() {
      _locale = Locale(langCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TouchFishAstra',
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.springFestivalThemeEnabled 
            ? Colors.red 
            : Colors.blue,
        ),
        useMaterial3: true,
        fontFamily: 'HarmonyOS Sans',
        appBarTheme: AppConstants.springFestivalThemeEnabled
          ? AppBarTheme(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            )
          : null,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.springFestivalThemeEnabled 
            ? Colors.red 
            : Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'HarmonyOS Sans',
        appBarTheme: AppConstants.springFestivalThemeEnabled
          ? AppBarTheme(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
            )
          : null,
      ),
      themeMode: _themeMode,
      home: _socket != null && _username != null
          ? MainNavigation(
              socket: _socket!,
              username: _username!,
              currentTheme: _themeMode,
              currentLocale: _locale,
              onThemeToggle: _toggleTheme,
              onLanguageChange: _changeLanguage,
            )
          : ConnectScreen(
              onThemeToggle: _toggleTheme,
              onLanguageChange: _changeLanguage,
              currentTheme: _themeMode,
              currentLocale: _locale,
              onConnected: _onConnected,
            ),
    );
  }
}

class ConnectScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final ThemeMode currentTheme;
  final Locale currentLocale;
  final Function(SocketService, String) onConnected;

  const ConnectScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentTheme,
    required this.currentLocale,
    required this.onConnected,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _ipController = TextEditingController(text: 'touchfish.xin');
  final _portController = TextEditingController(text: '7001');
  final _usernameController = TextEditingController();
  var _connecting = false;
  var _rememberConfig = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_config') ?? false;

    if (remember) {
      setState(() {
        _rememberConfig = true;
        _ipController.text = prefs.getString('server_ip') ?? 'touchfish.xin';
        _portController.text = prefs.getString('server_port') ?? '7001';
        _usernameController.text = prefs.getString('username') ?? '';
      });
    }
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberConfig) {
      await prefs.setBool('remember_config', true);
      await prefs.setString('server_ip', _ipController.text.trim());
      await prefs.setString('server_port', _portController.text.trim());
      await prefs.setString('username', _usernameController.text.trim());
    } else {
      await prefs.remove('remember_config');
      await prefs.remove('server_ip');
      await prefs.remove('server_port');
      await prefs.remove('username');
    }
  }

  Future<void> _connect() async {
    final l10n = AppLocalizations.of(context);
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final username = _usernameController.text.trim();

    if (ip.isEmpty || port == null || username.isEmpty) {
      _showError(l10n.fillAllFields);
      return;
    }
    await _saveConfig();

    setState(() => _connecting = true);

    final socket = SocketService();
    final success = await socket.connect(ip, port, username);

    if (!mounted) return;

    if (success) {
      widget.onConnected(socket, username);
    } else {
      setState(() => _connecting = false);
      _showError(l10n.connectionFailed);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text(l10n.settings)),
                body: SettingsScreen(
                  currentTheme: widget.currentTheme,
                  currentLocale: widget.currentLocale,
                  onThemeToggle: widget.onThemeToggle,
                  onLanguageChange: widget.onLanguageChange,
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('${l10n.version} ${AppConstants.version}'),
                  if (AppConstants.springFestivalThemeEnabled) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.amber.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.springFestivalGreeting,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: l10n.serverIp,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: l10n.port,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: l10n.username,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _connect(),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _rememberConfig,
                    onChanged: (value) {
                      setState(() {
                        _rememberConfig = value ?? false;
                      });
                    },
                    title: Text(l10n.rememberConfig),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _connecting ? null : _connect,
                      child: _connecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.connect),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}
