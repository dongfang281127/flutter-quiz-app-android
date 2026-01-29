import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ✨ 1. 引入 dotenv 包
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✨ 2. 加载环境变量文件
  await dotenv.load(fileName: ".env");

  // ✨ 3. 使用环境变量里的值
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '', // 如果读不到给个空字符串防报错
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

// ... 下面的代码保持不变 ...

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = true;

  @override
  void initState() {
    super.initState();
    // ✨✨✨ 核心魔法：设置监听器 ✨✨✨
    // 这就像在门口放了一个守卫，只要登录状态发生变化（比如登录了，或者退出了）
    // 它就会喊一声 setState，刷新界面。
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
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
      title: '魔法刷题',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,

      // ✨✨✨ 修复点：.session 改为 .auth.currentSession ✨✨✨
      // 如果 currentSession 不为空，说明有通行证 -> 进主页
      // 否则 -> 去登录页
      home: Supabase.instance.client.auth.currentSession != null
          ? MainScreen(
        isDark: _isDarkTheme,
        onThemeChanged: _toggleTheme,
      )
          : const LoginPage(),
    );
  }
}