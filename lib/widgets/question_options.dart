import 'package:flutter/material.dart';

class QuestionOptions extends StatelessWidget {
  final List<String> options;
  final Set<int> selectedIndices; 
  final bool isMultiSelect;       
  final bool isAnswerRevealed;
  final List<int> correctIndices; 
  final Function(int) onOptionTap;

  const QuestionOptions({
    super.key,
    required this.options,
    required this.selectedIndices,
    this.isMultiSelect = false,
    required this.isAnswerRevealed,
    required this.correctIndices,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: List.generate(options.length, (index) {
        String letter = String.fromCharCode(65 + index); // A, B, C...
        bool isSelected = selectedIndices.contains(index);
        bool isCorrect = correctIndices.contains(index);

        // --- 🎨 颜色逻辑修复 ---
        Color bgColor = Colors.transparent;
        Color borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
        // 默认文字颜色：跟随系统
        Color textColor = isDark ? Colors.white : Colors.black; 

        if (isAnswerRevealed) {
          // 揭晓答案后
          if (isCorrect) {
            bgColor = Colors.green.withOpacity(0.2);
            borderColor = Colors.green;
            textColor = Colors.green; // 正确答案文字变绿
          } else if (isSelected && !isCorrect) {
            bgColor = Colors.red.withOpacity(0.2);
            borderColor = Colors.red;
            textColor = Colors.red; // 错选文字变红
          }
        } else {
          // 答题中
          if (isSelected) {
            // ✨✨✨ 修复点：选中状态下，背景是深色，所以文字强制为白色 ✨✨✨
            bgColor = Theme.of(context).primaryColor;
            borderColor = Theme.of(context).primaryColor;
            textColor = Colors.white; 
          }
        }

        return GestureDetector(
          onTap: () => onOptionTap(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(
                color: borderColor, 
                width: isSelected || (isAnswerRevealed && isCorrect) ? 2 : 1
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // 选项圆圈/方块
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // 选中时填充颜色，未选中透明
                    color: isSelected 
                        ? (isAnswerRevealed 
                            ? (isCorrect ? Colors.green : Colors.red) // 揭晓后颜色
                            : Colors.white) // 答题中选中时，方块内部变白
                        : Colors.transparent, 
                    shape: isMultiSelect ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: isMultiSelect ? BorderRadius.circular(4) : null,
                    border: Border.all(
                      // 选中时边框变白(因为背景是深色)，未选中灰色
                      color: isSelected ? Colors.white : Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      // 选中时字母变回主题色(因为方块是白的)，未选中灰色
                      color: isSelected 
                          ? (isAnswerRevealed 
                              ? Colors.white 
                              : Theme.of(context).primaryColor)
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    options[index],
                    style: TextStyle(
                      fontSize: 16, 
                      color: textColor, // 使用上面计算好的颜色
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                // 结果图标
                if (isAnswerRevealed)
                  if (isCorrect)
                    const Icon(Icons.check_circle, color: Colors.green, size: 20)
                  else if (isSelected)
                    const Icon(Icons.cancel, color: Colors.red, size: 20),
              ],
            ),
          ),
        );
      }),
    );
  }
}