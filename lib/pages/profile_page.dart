import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'my_messages_page.dart';

class ProfilePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeChanged;

  const ProfilePage({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 用来控制页面刷新（比如改名后立马变）
  String _displayName = "加载中...";
  String _email = "";

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // 一进来就去查户口
  }

  // --- 1. 获取用户信息 ---
  void _loadUserProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email ?? "";
        // Supabase 的 metadata 里存着 display_name
        // 如果没设置过，就默认显示 "未命名巫师"
        _displayName = user.userMetadata?['display_name'] ?? "未命名巫师";
      });
    }
  }

  // --- 2. 修改昵称逻辑 ---
  Future<void> _updateNickname() async {
    // 弹出一个对话框让用户输入
    final TextEditingController nameController = TextEditingController(text: _displayName);
    
    String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改魔法代号'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "输入新昵称"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 取消
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nameController.text.trim()), // 确定
              child: const Text('确认修改'),
            ),
          ],
        );
      },
    );

    // 如果用户没输入或者取消了
    if (newName == null || newName.isEmpty) return;

    try {
      // 发送更新指令给 Supabase
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'display_name': newName}, // 存到 metadata 里
        ),
      );

      // 界面刷新
      setState(() {
        _displayName = newName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更名成功！'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更名失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 3. 退出登录 ---
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  // --- 4. 注销账户 (自毁) ---
  Future<void> _deleteAccount() async {
    // 二次确认弹窗
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('⚠️ 危险操作'),
          content: const Text('确定要永久注销账户吗？\n你的所有数据将被清除，且无法恢复！'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('我点错了'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('确认注销'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // 调用我们在 SQL 里写的 delete_user 函数
      await Supabase.instance.client.rpc('delete_user');
      
      // 同时也需要在本地执行退出，清理缓存
      await Supabase.instance.client.auth.signOut();
      
      // main.dart 会自动监听到退出，跳回登录页

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('注销失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('巫师档案')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          
          // --- 头像和昵称区 ---
          Center(
            child: Column(
              children: [
                // 头像
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                  ),
                  child: Icon(Icons.person, size: 60, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 15),
                
                // 昵称 (点击旁边的小笔可以修改)
                InkWell(
                  onTap: _updateNickname, // 点击触发修改
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _displayName, 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 5),
                Text("邮箱: $_email", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          const Divider(), 
          
          // --- 设置选项 ---
          SwitchListTile(
            secondary: Icon(widget.isDark ? Icons.nights_stay : Icons.wb_sunny),
            title: const Text('斯莱特林环境模式'),
            subtitle: Text(widget.isDark ? '当前：暗黑森林' : '当前：明亮教室'),
            value: widget.isDark,
            onChanged: (bool value) => widget.onThemeChanged(),
          ),
          
          // ... 在 SwitchListTile (环境模式) 下面添加 ...
          
          ListTile(
            leading: const Icon(Icons.mail_outline, color: Colors.blue),
            title: const Text('我的猫头鹰信箱'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 跳转到刚才新建的信箱页
              // 记得在顶部 import 'my_messages_page.dart';
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyMessagesPage()));
            },
          ),

          // --- 危险区域 ---
          const SizedBox(height: 40),
          const Text("账户管理", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),

          // 退出登录
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('退出登录'),
            onTap: _signOut,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: Colors.grey.withOpacity(0.1),
          ),
          
          const SizedBox(height: 10),

          // 注销账户
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('注销账户 (永久删除)'),
            onTap: _deleteAccount,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: Colors.red.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}