import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentSection extends StatefulWidget {
  final int questionId;
  final bool isAnswerRevealed; // 父组件告诉我们，答案揭晓没？

  const CommentSection({
    super.key,
    required this.questionId,
    required this.isAnswerRevealed,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 一进来就加载评论
    _loadComments();
  }

  // ✨✨✨ 核心：当父组件传来的 questionId 发生变化时（翻页了），重新加载评论
  @override
  void didUpdateWidget(covariant CommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionId != widget.questionId) {
      _loadComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- 逻辑部分 (直接从 ExamPage 搬过来的) ---

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final response = await Supabase.instance.client
          .from('question_comments')
          .select()
          .eq('question_id', widget.questionId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response);
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录才能评论')));
      return;
    }

    String nickname = user.userMetadata?['display_name'] ?? "神秘巫师";

    try {
      // 乐观更新
      Map<String, dynamic> newComment = {
        'user_nickname': nickname,
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user.id,
        'id': -1, // 临时ID
      };

      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
        FocusScope.of(context).unfocus();
      });

      await Supabase.instance.client.from('question_comments').insert({
        'question_id': widget.questionId,
        'user_id': user.id,
        'content': text,
        'user_nickname': nickname,
      });

      _loadComments(); // 刷新获取真实ID
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
      }
    }
  }

  Future<void> _deleteComment(int commentId, int index) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定要撤回这条消息吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        _comments.removeAt(index);
      });

      if (commentId != -1) {
        await Supabase.instance.client
            .from('question_comments')
            .delete()
            .eq('id', commentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败')));
        _loadComments();
      }
    }
  }

  // --- UI 部分 ---

  @override
  Widget build(BuildContext context) {
    // 1. 如果没揭晓答案，显示“赤胆忠心咒”锁定界面
    if (!widget.isAnswerRevealed) {
      return Container(
        padding: const EdgeInsets.all(30),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              "尘封思绪，待君破局\n答题后解锁",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // 2. 如果揭晓了，显示正常的评论列表
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("讨论区", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        if (_isLoadingComments)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_comments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "还没有人讨论这道题，来抢沙发！",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._comments.asMap().entries.map((entry) {
            int idx = entry.key;
            var c = entry.value;
            String rawTime = c['created_at']?.toString() ?? "";
            String timeStr = rawTime.length > 10 ? rawTime.substring(0, 10) : rawTime;
            bool isMine = c['user_id'] == currentUserId;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: isMine ? Colors.green.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                        child: Icon(Icons.person, size: 12, color: isMine ? Colors.green : Colors.purple),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isMine ? "${c['user_nickname']} (我)" : (c['user_nickname'] ?? "匿名"),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isMine ? Colors.green : null,
                        ),
                      ),
                      const Spacer(),
                      Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      if (isMine)
                        GestureDetector(
                          onTap: () => _deleteComment(c['id'], idx),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(c['content'] ?? "", style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),

        const SizedBox(height: 10),
        
        // 发送输入框
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "写下你的见解...",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendComment,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _commentController.text.trim().isEmpty
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}