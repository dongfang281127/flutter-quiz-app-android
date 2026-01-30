import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/app_theme.dart';
import 'pages/splash_page.dart'; // 开屏页
import 'pages/login_page.dart';  // ✨ 必须引入登录页，用于强制跳转

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // ✨ 1. 定义一把“万能钥匙”
  // 它可以让我们在任何地方（比如监听器里）控制页面跳转
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = true;

  @override
  void initState() {
    super.initState();
    // 监听登录状态变化
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      // ✨✨✨ 核心修复代码 ✨✨✨
      // 如果检测到“用户退出了” (SIGNED_OUT)
      if (event == AuthChangeEvent.signedOut) {
        // 使用万能钥匙，强制清空所有页面，跳转到登录页
        MyApp.navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(
              isDark: _isDarkTheme,
              onThemeChanged: _toggleTheme,
            ),
          ),
              (route) => false, // 这里的 false 表示删掉之前所有的页面记录
        );
      }

      // 保持原本的 setState 用来更新 UI
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ✨ 2. 把钥匙交给 MaterialApp
      navigatorKey: MyApp.navigatorKey,

      title: '问道', // 你的 App 名字
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,

      // 启动时依然先去开屏页
      home: SplashPage(
        isDark: _isDarkTheme,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}