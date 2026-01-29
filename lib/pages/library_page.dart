import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'exam_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  Map<String, List<Map<String, dynamic>>> _myLibrary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserFavorites();
  }

  Future<void> _fetchUserFavorites() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. 先查收藏了哪些试卷名
      final List<dynamic> favResponse = await Supabase.instance.client
          .from('favorites')
          .select('group_name')
          .eq('user_id', user.id);

      if (favResponse.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      List<String> myGroupNames = favResponse.map((e) => e['group_name'].toString()).toList();

      // 2. 根据名字查具体题目
      final List<dynamic> questionResponse = await Supabase.instance.client
          .from('questions')
          .select()
          .inFilter('group_name', myGroupNames)
          .order('created_at', ascending: false);

      // 3. 组装数据
      Map<String, List<Map<String, dynamic>>> tempGroup = {};
      
      for (var item in questionResponse) {
        String groupName = item['group_name']?.toString() ?? "未知试卷";
        
        Map<String, dynamic> questionData = {
          'id': item['id'], 
          'question': item['question'].toString(),
          'options': item['options'].toString(),
          'answer': item['answer'].toString(),
          // ✨✨✨ 关键补充：把作者ID带上，否则考场里没法发信！
          'created_by': item['created_by']?.toString(),
          // ✨✨✨ 顺便把试卷名也带上，作为信件的标题
          'group_name': groupName,
        };

        if (!tempGroup.containsKey(groupName)) {
          tempGroup[groupName] = [];
        }
        tempGroup[groupName]!.add(questionData);
      }

      if (mounted) {
        setState(() {
          _myLibrary = tempGroup;
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromLibrary(String groupName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    // 只是删除收藏记录，不动原始题库
    await Supabase.instance.client
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('group_name', groupName);
        
    setState(() { 
      _myLibrary.remove(groupName); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的私人图书馆'), 
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () { 
              setState(() => _isLoading = true); 
              _fetchUserFavorites(); 
            }
          )
        ]
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myLibrary.isEmpty
              ? const Center(child: Text("暂无收藏"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myLibrary.length,
                  itemBuilder: (context, index) {
                    String groupName = _myLibrary.keys.elementAt(index);
                    List<Map<String, dynamic>> questions = _myLibrary[groupName]!;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(Icons.book, color: Colors.blue),
                        title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${questions.length} 道题"),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red), 
                          onPressed: () => _removeFromLibrary(groupName)
                        ),
                        onTap: () {
                          // 直接传递整理好的数据 (已经包含了 created_by)
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => ExamPage(questions: questions)
                            )
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}