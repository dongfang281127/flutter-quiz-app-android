import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'main_screen.dart';

class SplashPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeChanged;

  const SplashPage({
    super.key,
    required this.isDark,
    required this.onThemeChanged
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _textController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;

  // --- 斯莱特林风格配色 ---
  final Color _magicGlowColorPrimary = const Color(0xFF2E8B57); // 亮祖母绿 (光晕)
  final Color _magicGlowColorSecondary = const Color(0xFF1A472A); // 深墨绿 (外围)
  final Color _textColorSilver = const Color(0xFFC0C0C0); // 银灰文字
  // ✨ 新增：图腾颜色，比背景稍亮一点的墨绿，像刻痕
  final Color _totemColor = const Color(0xFF145235);

  @override
  void initState() {
    super.initState();

    // 1. 呼吸动画
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutCubic),
    );

    // 2. 文字动画
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInSine),
    );

    _textSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutQuart),
    );

    // 3. 启动流程
    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    _textController.forward();

    Timer(const Duration(seconds: 5), () {
      _checkSessionAndNavigate();
    });
  }

  void _checkSessionAndNavigate() {
    final session = Supabase.instance.client.auth.currentSession;

    Widget nextPage;
    if (session != null) {
      nextPage = MainScreen(
        isDark: widget.isDark,
        onThemeChanged: widget.onThemeChanged,
      );
    } else {
      // ✨ 把参数传递给 LoginPage
      nextPage = LoginPage(
        isDark: widget.isDark,
        onThemeChanged: widget.onThemeChanged,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1500),
        pageBuilder: (_, __, ___) => nextPage,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.4,
              colors: const [
                Color(0xFF0D3A28),
                Color(0xFF000000),
              ],
              stops: const [0.1, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // --- 银色灵珠 ---
              AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (context, child) {
                  double range = 1.3 - 0.8;
                  double t = (_breathingAnimation.value - 0.8) / range;

                  return Transform.scale(
                    scale: _breathingAnimation.value,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          center: Alignment(-0.3, -0.3),
                          colors: [
                            Colors.white,
                            Color(0xFFE0E0E0),
                            Color(0xFF909090),
                          ],
                          stops: [0.1, 0.4, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _magicGlowColorPrimary.withOpacity(0.6 * t + 0.3),
                            blurRadius: 30 * t + 10,
                            spreadRadius: 5 * t + 2,
                          ),
                          BoxShadow(
                            color: _magicGlowColorSecondary.withOpacity(0.4 * t + 0.1),
                            blurRadius: 60 * t + 40,
                            spreadRadius: 20 * t + 10,
                          ),
                        ],
                      ),
                      // ✨✨✨ 核心修改：衔尾蛇图腾 ✨✨✨
                      child: Center(
                        child: Icon(
                          // 使用 "all_inclusive" 代表盘绕的蛇/无限符号
                          Icons.all_inclusive,
                          // 使用深墨绿色，就像嵌在银珠里的刻痕
                          color: _totemColor,
                          size: 45,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // --- 文字部分 ---
              Positioned(
                top: MediaQuery.of(context).size.height * 0.5 + 130,
                child: SlideTransition(
                  position: _textSlideAnimation,
                  child: FadeTransition(
                    opacity: _textOpacityAnimation,
                    child: Column(
                      children: [
                        Text(
                          '问 道',
                          style: TextStyle(
                              color: _textColorSilver,
                              fontSize: 28,
                              letterSpacing: 14,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'Serif',
                              shadows: [
                                Shadow(
                                  color: _magicGlowColorPrimary.withOpacity(0.5),
                                  blurRadius: 15,
                                )
                              ]
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '万籁俱寂 · 唯思不止',
                          style: TextStyle(
                            color: _textColorSilver.withOpacity(0.5),
                            fontSize: 13,
                            letterSpacing: 4,
                            fontFamily: 'Serif',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}