import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'exam_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // 结构：{ "试卷名": [题目1, 题目2...] }
  // 顺便我们要把 "meta信息" (作者、ID) 也存起来，所以稍微改一下结构
  // Map<GroupString, { "questions": [], "author":Str, "ownerId":Str }>
  Map<String, Map<String, dynamic>> _searchResults = {};
  
  bool _isLoading = true;
  Timer? _debounce;
  Set<String> _myFavorites = {};

  @override
  void initState() {
    super.initState();
    _fetchFavoritesAndData();
  }

  Future<void> _fetchFavoritesAndData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final favs = await Supabase.instance.client
          .from('favorites')
          .select('group_name')
          .eq('user_id', user.id);
      
      if (mounted) {
        setState(() {
          _myFavorites = favs.map((e) => e['group_name'].toString()).toSet();
        });
      }
    }
    _fetchAllPublicBanks();
  }

  Future<void> _fetchAllPublicBanks([String? keyword]) async {
    setState(() => _isLoading = true);
    try {
      var query = Supabase.instance.client.from('questions').select();
      if (keyword != null && keyword.trim().isNotEmpty) {
        query = query.ilike('group_name', '%$keyword%');
      }
      final List<dynamic> response = await query.order('created_at', ascending: false);

      Map<String, Map<String, dynamic>> tempGroup = {};
      
      for (var item in response) {
        String groupName = item['group_name']?.toString() ?? "未知试卷";
        
        // ✨ 获取作者信息
        String author = item['author_name']?.toString() ?? "未知";
        String? ownerId = item['created_by']?.toString();

        Map<String, dynamic> questionData = {
          'id': item['id'], 
          'question': item['question'].toString(),
          'options': item['options'].toString(),
          'answer': item['answer'].toString(),
        };

        if (!tempGroup.containsKey(groupName)) {
          tempGroup[groupName] = {
            "questions": <Map<String, dynamic>>[],
            "author": author,
            "ownerId": ownerId,
          };
        }
        tempGroup[groupName]!["questions"].add(questionData);
      }

      if (mounted) setState(() { _searchResults = tempGroup; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addToLibrary(String groupName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录！')));
      return;
    }

    try {
      setState(() {
        _myFavorites.add(groupName);
      });

      await Supabase.instance.client.from('favorites').insert({
        'user_id': user.id,
        'group_name': groupName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已收藏《$groupName》'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() {
        _myFavorites.remove(groupName);
      });
      // 这里的错误通常是重复收藏，忽略即可
    }
  }

  // --- ✨ 新增：作者删除自己的题库 ---
  Future<void> _deleteMyBank(String groupName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除题库'),
        content: Text('确定要永久删除《$groupName》吗？\n所有人的收藏和做题记录也会失效。'),
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
      setState(() => _isLoading = true);
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. 删除 questions 表里的数据 (级联通常会处理关联表，如果没设级联可能需要手动删)
      // 我们在 SQL 里设置了 policy，只允许删自己的
      await Supabase.instance.client
          .from('questions')
          .delete()
          .eq('group_name', groupName)
          .eq('created_by', user.id); // 双重保险

      // 2. 刷新列表
      await _fetchAllPublicBanks(_searchController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('题库已删除')));
      }

    } catch (e) {
      print("删除失败: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () => _fetchAllPublicBanks(value));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color hintColor = isDark ? Colors.white60 : Colors.black54;
    final Color iconColor = isDark ? Colors.white70 : Colors.black54;
    final Color boxBgColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05);

    // 获取当前用户ID
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: boxBgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(color: textColor), 
            cursorColor: textColor,
            decoration: InputDecoration(
              hintText: '搜索公共题库...',
              hintStyle: TextStyle(color: hintColor),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: iconColor),
              contentPadding: const EdgeInsets.only(top: 5),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(child: Text("没有找到相关试卷", style: TextStyle(color: hintColor)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.keys.length,
                  itemBuilder: (context, index) {
                    String groupName = _searchResults.keys.elementAt(index);
                    var groupData = _searchResults[groupName]!;
                    List<Map<String, dynamic>> questions = groupData["questions"];
                    String author = groupData["author"];
                    String? ownerId = groupData["ownerId"];
                    
                    bool isBookmarked = _myFavorites.contains(groupName);
                    
                    // ✨ 判断：这是不是我上传的？
                    bool isMine = (currentUserId != null && ownerId == currentUserId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isMine ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                          child: Icon(Icons.description, color: isMine ? Colors.green : Colors.blue),
                        ),
                        title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("题目: ${questions.length} 道"),
                            // ✨ 显示作者
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  isMine ? "我上传的" : author, 
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: isMine ? Colors.green : Colors.grey
                                  )
                                ),
                              ],
                            )
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✨ 如果是我的，显示删除按钮
                            if (isMine)
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                tooltip: "删除我的题库",
                                onPressed: () => _deleteMyBank(groupName),
                              ),
                              
                            // 收藏按钮
                            IconButton(
                              icon: Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
                                color: isBookmarked ? Theme.of(context).primaryColor : Colors.orange,
                              ),
                              onPressed: isBookmarked ? null : () => _addToLibrary(groupName),
                            ),
                          ],
                        ),
                        onTap: () {
                          List<Map<String, dynamic>> safeQuestions = questions.map((q) {
                            return {
                              'id': q['id'], 
                              "question": q["question"].toString(),
                              "options": q["options"].toString(),
                              "answer": q["answer"].toString(),
                              "created_by": q["created_by"]?.toString(), 
                              "group_name": groupName, // 顺便把试卷名也带上，发信要用
                            };
                          }).toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExamPage(questions: safeQuestions)),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}