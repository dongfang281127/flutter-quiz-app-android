import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class MyMessagesPage extends StatefulWidget {
  const MyMessagesPage({super.key});

  @override
  State<MyMessagesPage> createState() => _MyMessagesPageState();
}

class _MyMessagesPageState extends State<MyMessagesPage> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('author_messages')
          .select()
          .eq('receiver_id', user.id) // 查发给我的
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMessage(int id, int index) async {
    try {
      await Supabase.instance.client.from('author_messages').delete().eq('id', id);
      setState(() {
        _messages.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('信箱')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.mark_email_unread_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("暂时没有新消息", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    var msg = _messages[index];
                    String time = msg['created_at'].toString().substring(0, 10); // 简单日期

                    return Dismissible(
                      key: Key(msg['id'].toString()),
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      onDismissed: (direction) => _deleteMessage(msg['id'], index),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.account_circle, size: 20, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(msg['sender_nickname'] ?? "匿名", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  "来源: 《${msg['group_name']}》\n题目: ${msg['question_preview']}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(msg['message_content'], style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}