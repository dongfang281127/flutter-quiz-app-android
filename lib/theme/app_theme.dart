import 'package:flutter/material.dart';

// 这是一个工具类，专门提供主题配置
class AppTheme {
  // 私有构造函数，防止被误实例化
  AppTheme._();

  // --- 白天模式配置 ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.lightGreen[200],
    scaffoldBackgroundColor: const Color(0xFFF1F8E9), // 浅薄荷色
    colorScheme: ColorScheme.light(
      primary: Colors.lightGreen,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black87,
    ),
    useMaterial3: true,
  );

  // --- 斯莱特林暗黑模式配置 ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A1612), // 深渊黑绿
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1A472A), // 斯莱特林绿
      onPrimary: Color(0xFFC0C0C0), // 银色
      secondary: Color(0xFF2A623D),
      surface: Color(0xFF11221C),
      onSurface: Color(0xFFE0E0E0),
    ),
    useMaterial3: true,
  );
}