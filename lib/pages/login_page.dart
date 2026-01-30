import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_screen.dart'; // ✨ 引入主页，因为我们要跳转过去

class LoginPage extends StatefulWidget {
  // ✨ 1. 接收主题参数，为了传给 MainScreen
  final bool isDark;
  final VoidCallback onThemeChanged;

  const LoginPage({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;

  // 斯莱特林配色
  final Color _accentGreen = const Color(0xFF2E8B57); // 祖母绿
  final Color _textSilver = const Color(0xFFC0C0C0); // 银灰

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMsg('请输入邮箱和密码', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
      }

      if (mounted) {
        _showMsg(_isLoginMode ? '欢迎归来' : '注册成功，已自动登录');

        // ✨✨✨ 重点修复：手动跳转到主页 ✨✨✨
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainScreen(
              isDark: widget.isDark,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
        );
      }

    } on AuthException catch (e) {
      if (mounted) _showMsg(e.message, isError: true);
    } catch (e) {
      if (mounted) _showMsg('发生错误: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[900] : _accentGreen,
        behavior: SnackBarBehavior.floating, // 悬浮样式更高级
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 强制深色背景
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF0D3A28), // 深绿中心
              Color(0xFF000000), // 纯黑边缘
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 顶部图标
                Icon(Icons.lock_outline, size: 60, color: _textSilver),
                const SizedBox(height: 20),

                // 标题
                Text(
                  _isLoginMode ? '推开真理之扉' : '静候智者',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: _textSilver,
                    letterSpacing: 4,
                    fontFamily: 'Serif',
                  ),
                ),
                const SizedBox(height: 50),

                // 输入框 1
                _buildTextField(_emailController, '邮箱', Icons.email_outlined),
                const SizedBox(height: 20),

                // 输入框 2
                _buildTextField(_passwordController, '密码', Icons.key_outlined, isObscure: true),

                const SizedBox(height: 40),

                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGreen, // 祖母绿按钮
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: _accentGreen.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                        : Text(
                      _isLoginMode ? '启程' : '提交申请',
                      style: const TextStyle(fontSize: 16, letterSpacing: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 切换模式
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                    });
                  },
                  child: Text(
                    _isLoginMode ? '初来乍到？由此入道' : '已有身份？由此归位',
                    style: TextStyle(color: _textSilver.withOpacity(0.6), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 封装一个好看的输入框样式
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: TextStyle(color: _textSilver), // 输入文字颜色
      cursorColor: _accentGreen,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textSilver.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: _accentGreen),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05), // 半透明背景
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _textSilver.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentGreen), // 选中变绿
        ),
      ),
    );
  }
}