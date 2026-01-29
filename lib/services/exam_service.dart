import 'package:supabase_flutter/supabase_flutter.dart';

class ExamService {
  final SupabaseClient _client = Supabase.instance.client;

  /// 获取用户的做题记录 (用于恢复进度)
  Future<Map<int, Map<String, dynamic>>> fetchUserProgress({
    required String userId,
    required List<int> questionIds,
  }) async {
    try {
      if (questionIds.isEmpty) return {};

      final response = await _client
          .from('user_records')
          .select('question_id, is_correct, selected_option_index')
          .eq('user_id', userId)
          .inFilter('question_id', questionIds);

      final List<dynamic> data = response as List<dynamic>;
      Map<int, Map<String, dynamic>> history = {};

      for (var record in data) {
        history[record['question_id']] = {
          'isCorrect': record['is_correct'] ?? false,
          'selectedIndex': record['selected_option_index'] ?? -1,
        };
      }
      return history;
    } catch (e) {
      print("获取进度失败: $e");
      return {};
    }
  }

  /// ✨✨✨ 核心修复：保存/更新进度 ✨✨✨
  Future<void> saveProgress({
    required String userId,
    required int questionId,
    required bool isCorrect,
    required int selectedOptionIndex,
  }) async {
    try {
      // 使用 upsert：如果 (user_id, question_id) 存在则更新，不存在则插入
      // 注意：这需要在 Supabase 里设置 user_records 表的 (user_id, question_id) 为复合唯一键(Unique Constraint)
      // 如果你没设置唯一键，下面的代码可能会报错，建议去 Supabase SQL Editor 执行:
      // ALTER TABLE user_records ADD CONSTRAINT unique_user_question UNIQUE (user_id, question_id);
      
      await _client.from('user_records').upsert({
        'user_id': userId,
        'question_id': questionId,
        'is_correct': isCorrect,
        'selected_option_index': selectedOptionIndex,
        'created_at': DateTime.now().toIso8601String(), // 更新时间
      }, onConflict: 'user_id, question_id'); // 指定冲突检测字段
      
    } catch (e) {
      print("保存进度失败: $e");
      // 如果 upsert 失败（可能是因为没有唯一约束），尝试先删后插的笨办法作为兜底
      try {
        await _client.from('user_records').delete().match({
          'user_id': userId, 
          'question_id': questionId
        });
        await _client.from('user_records').insert({
          'user_id': userId,
          'question_id': questionId,
          'is_correct': isCorrect,
          'selected_option_index': selectedOptionIndex,
        });
      } catch (e2) {
        print("兜底保存也失败: $e2");
      }
    }
  }

  /// 重置进度
  Future<void> resetProgress({required String userId, required List<int> questionIds}) async {
    if (questionIds.isEmpty) return;
    await _client
        .from('user_records')
        .delete()
        .eq('user_id', userId)
        .inFilter('question_id', questionIds);
  }

  /// 发送留言 (保持不变)
  Future<void> sendOwlMessage({
    required String senderId,
    required String receiverId,
    required String senderNickname,
    required String groupName,
    required String messageContent,
    required String questionContent,
  }) async {
    await _client.from('author_messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'sender_nickname': senderNickname,
      'group_name': groupName,
      'message_content': messageContent,
      'question_preview': questionContent.length > 50 
          ? "${questionContent.substring(0, 50)}..." 
          : questionContent,
    });
  }
}