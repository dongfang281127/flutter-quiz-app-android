import 'package:flutter/material.dart';
// 引入刚才写的4个页面
import 'library_page.dart';
import 'search_page.dart';
import 'add_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  // 我们需要把主题状态和切换函数传进来，传给 ProfilePage 用
  final bool isDark;
  final VoidCallback onThemeChanged;

  const MainScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 1. 定义一个变量，记录当前选中的是第几个按钮（0, 1, 2, 3）
  // 默认是 0，也就是首页
  int _currentIndex = 0;

  // 2. 这个函数专门处理底部导航栏的点击事件
  void _onItemTapped(int index) {
    setState(() {
      // 更新当前索引，Flutter 会自动重绘页面
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. 把4个页面放进一个列表里
    // 这样我们可以通过 _pages[_currentIndex] 来取到当前应该显示的页面
    final List<Widget> pages = [
      const LibraryPage(),         // 索引 0: 首页
      const SearchPage(),          // 索引 1: 搜索
      const AddPage(),             // 索引 2: 添加
      // 索引 3: 个人中心 (注意：这里把父组件传来的参数透传进去)
      ProfilePage(
        isDark: widget.isDark,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      // body 显示当前选中的那个页面
      body: pages[_currentIndex],

      // bottomNavigationBar 就是底部的导航条
      bottomNavigationBar: NavigationBar(
        // 当前选中的索引
        selectedIndex: _currentIndex,
        // 点击时的回调函数
        onDestinationSelected: _onItemTapped,
        // 如果是斯莱特林模式，背景色微调一下
        backgroundColor: Theme.of(context).colorScheme.surface,
        // 定义底部的四个按钮
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined), // 未选中时的图标
            selectedIcon: Icon(Icons.home),  // 选中时的图标
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '搜索',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: '添加',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}