import 'package:flutter/material.dart';
import '../models/question.dart'; // ✨ 引入模型类

class QuestionGrid extends StatelessWidget {
  final List<Question> questions; // ✨ 改用强类型
  final Map<int, Map<String, dynamic>> historyMap; // 历史记录
  final int currentIndex; // 当前正在做的题号
  final Function(int) onJumpToQuestion; // 跳转回调
  final VoidCallback onResetProgress; // 重置回调

  const QuestionGrid({
    super.key,
    required this.questions,
    required this.historyMap,
    required this.currentIndex,
    required this.onJumpToQuestion,
    required this.onResetProgress,
  });

  @override
  Widget build(BuildContext context) {
    // 获取屏幕高度，限制弹窗高度不超过屏幕的 80%
    final double maxHeight = MediaQuery.of(context).size.height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // 跟随系统/暗黑模式背景
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 顶部标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '题目列表 (${questions.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  // 二次确认弹窗
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("确定重置？"),
                      content: const Text("这将清除本套题目的所有做题记录。"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("取消"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx); // 关掉确认框
                            onResetProgress(); // 调用外部传入的重置逻辑
                          },
                          child: const Text("重置", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                label: const Text("重置进度", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          const Divider(),
          
          // 2. 题目网格
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 一行 5 个
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final int qId = question.id;
                
                // 判断状态
                bool isAnswered = historyMap.containsKey(qId);
                bool isCorrect = false;
                if (isAnswered) {
                  isCorrect = historyMap[qId]?['isCorrect'] ?? false;
                }
                
                // 判断是不是当前正在做的这道题
                bool isCurrent = index == currentIndex;

                // 颜色逻辑
                Color bgColor = Colors.grey.withOpacity(0.1); // 默认未做：浅灰
                Color textColor = Colors.black; // 默认文字：黑 (暗黑模式下需调整)
                Color borderColor = Colors.transparent;

                // 适配暗黑模式的文字颜色
                if (Theme.of(context).brightness == Brightness.dark) {
                  textColor = Colors.white;
                }

                if (isAnswered) {
                  if (isCorrect) {
                    bgColor = Colors.green.withOpacity(0.2);
                    textColor = Colors.green;
                    borderColor = Colors.green;
                  } else {
                    bgColor = Colors.red.withOpacity(0.2);
                    textColor = Colors.red;
                    borderColor = Colors.red;
                  }
                }

                if (isCurrent) {
                  borderColor = Theme.of(context).primaryColor;
                  // 如果未做且是当前题，加深一点背景
                  if (!isAnswered) {
                    bgColor = Theme.of(context).primaryColor.withOpacity(0.1);
                  }
                }

                return InkWell(
                  onTap: () => onJumpToQuestion(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(
                        color: borderColor, 
                        width: isCurrent ? 2 : 1 // 当前题目边框加粗
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}