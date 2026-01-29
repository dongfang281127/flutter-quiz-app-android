import 'package:flutter/material.dart';

// 定义 ExamMode (为了方便引用，或者你可以从 models 引入)
enum ExamMode { rapid, practice, memorize }

class ExamAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  final int totalCount;
  final bool isShuffleOn;       // 接收乱序状态
  final ExamMode currentMode;
  final VoidCallback onToggleSort; // 接收点击事件
  final VoidCallback onSendMessage;
  final VoidCallback onShowGrid;
  final Function(ExamMode) onModeChanged;

  const ExamAppBar({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.isShuffleOn,
    required this.currentMode,
    required this.onToggleSort,
    required this.onSendMessage,
    required this.onShowGrid,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('第 ${currentIndex + 1}/$totalCount 题'),
      actions: [
        // ✨ 这里就是我们要的新图标：位于屏幕右上角
        IconButton(
          icon: Icon(isShuffleOn ? Icons.shuffle : Icons.sort),
          tooltip: isShuffleOn ? "切换回顺序播放" : "切换为随机播放",
          onPressed: onToggleSort,
        ),

        IconButton(
            icon: const Icon(Icons.mail_outline),
            onPressed: onSendMessage
        ),

        IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: onShowGrid
        ),

        PopupMenuButton<ExamMode>(
          icon: const Icon(Icons.swap_horiz),
          initialValue: currentMode,
          onSelected: onModeChanged,
          itemBuilder: (context) => [
            const PopupMenuItem(value: ExamMode.rapid, child: Text("⚡ 快速模式")),
            const PopupMenuItem(value: ExamMode.practice, child: Text("🛡️ 练习模式")),
            const PopupMenuItem(value: ExamMode.memorize, child: Text("📖 背题模式")),
          ],
        ),
      ],
    );
  }

  // ✨ 这是 AppBar 必须实现的特殊设置：指定高度
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}