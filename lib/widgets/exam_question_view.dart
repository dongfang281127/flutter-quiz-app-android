import 'package:flutter/material.dart';
import '../models/question.dart';

// 引入你目录里已经存在的组件
import 'question_options.dart';
import 'comment_section.dart';

class ExamQuestionView extends StatelessWidget {
  final Question question;
  final List<String> currentOptions;
  final Set<int> selectedIndices;
  final bool isAnswerRevealed;
  final bool showSubmitBtn;

  // 回调函数：把点击事件传回给上一层去处理
  final VoidCallback onNextQuestion;
  final VoidCallback onPrevQuestion;
  final VoidCallback onSubmitAnswer;
  final Function(int) onOptionTap;

  const ExamQuestionView({
    super.key,
    required this.question,
    required this.currentOptions,
    required this.selectedIndices,
    required this.isAnswerRevealed,
    required this.showSubmitBtn,
    required this.onNextQuestion,
    required this.onPrevQuestion,
    required this.onSubmitAnswer,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 支持左右滑动切换题目
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) onNextQuestion();
        else if (details.primaryVelocity! > 0) onPrevQuestion();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 题目类型标签 和 题干
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(top: 4, right: 8),
                  decoration: BoxDecoration(
                    color: question.isMultiSelect ? Colors.purple : Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    question.isMultiSelect ? "多选" : "单选",
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Text(
                    question.text,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 2. 选项列表 (调用你已有的 QuestionOptions 组件)
            QuestionOptions(
              options: currentOptions,
              selectedIndices: selectedIndices,
              isMultiSelect: question.isMultiSelect,
              isAnswerRevealed: isAnswerRevealed,
              correctIndices: question.answerIndices,
              onOptionTap: onOptionTap,
            ),

            // 3. 确认按钮
            if (showSubmitBtn)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedIndices.isEmpty ? null : onSubmitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      question.isMultiSelect ? "提交多选答案" : "确认",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),

            // 4. 下一题按钮 (揭晓答案后显示)
            if (isAnswerRevealed)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onNextQuestion,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text("下一题"),
                  ),
                ),
              ),

            const Divider(height: 40),

            // 5. 评论区 (调用你已有的 CommentSection 组件)
            CommentSection(
              questionId: question.id,
              isAnswerRevealed: isAnswerRevealed,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}