import 'package:flutter/material.dart';

/// 全局应用主题配置
ThemeData buildAppTheme() {
  // 从种子色创建颜色方案
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E88E5), // 蓝色系
    secondary: const Color(0xFF43A047), // 绿色系
    brightness: Brightness.light,
  );

  return ThemeData(
    colorScheme: colorScheme,
    // 使用Roboto字体
    fontFamily: 'Roboto',
    
    // 卡片主题
    cardTheme: CardTheme(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // 8dp圆角
      ),
    ),
    
    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0), // 24dp圆角
        ),
      ),
    ),
    
    // AppBar主题
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    
    // 底部导航栏主题
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: Colors.grey,
    ),
    
    useMaterial3: true,
  );
}
