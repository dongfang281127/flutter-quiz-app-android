import 'package:flutter/material.dart';

class ExamStatsBar extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final int remainingCount;
  final String accuracy;

  const ExamStatsBar({
    super.key,
    required this.completedCount,
    required this.totalCount,
    required this.remainingCount,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    // 判断当前是否是暗黑模式
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        // 根据模式调整背景色
        color: isDark ? Colors.black45 : Colors.grey[200],
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem("已完成", "$completedCount / $totalCount", Colors.blue),
          _buildStatItem("剩余", "$remainingCount", Colors.orange),
          _buildStatItem("正确率", accuracy, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)
        ),
        Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10)
        ),
      ],
    );
  }
}