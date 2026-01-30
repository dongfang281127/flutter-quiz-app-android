import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✨✨✨ 引入我们拆分好的三个组件 ✨✨✨
import '../widgets/exam_app_bar.dart';      // 顶部导航栏 (含排序按钮)
import '../widgets/exam_question_view.dart'; // 中间题目显示
import '../widgets/exam_stats_bar.dart';     // 底部统计条

// 引入其他必要的模型和服务
import '../models/question.dart';
import '../services/exam_service.dart';
import '../widgets/owl_message_dialog.dart';
import '../widgets/question_grid.dart';

// ⚠️ 注意：如果 ExamMode 已经在 exam_app_bar.dart 里定义了，
// 这里就不需要再定义，否则会报错“重复定义”。
// 如果报错找不到 ExamMode，请取消下面这行的注释：
// enum ExamMode { rapid, practice, memorize }

class ExamPage extends StatefulWidget {
  final List<Map<String, dynamic>> questionsRaw;

  const ExamPage({super.key, required List<Map<String, dynamic>> questions})
      : questionsRaw = questions;

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final ExamService _examService = ExamService();

  late List<Question> _allQuestions;
  late List<Question> _displayQuestions; // 当前用于显示的题目列表
  List<Question> _sequentialQuestions = []; // ✨ 备份：永远保持顺序的列表

  int _currentIndex = 0;
  int _sessionCorrectCount = 0;
  int _sessionAttempted = 0;
  ExamMode _currentMode = ExamMode.rapid;

  // ✨✨✨ 核心状态：是否开启乱序 ✨✨✨
  bool _isShuffleOn = false;

  int _selectedOptionIndex = -1;
  Set<int> _selectedIndicesSet = {};

  bool _isAnswerRevealed = false;
  Map<int, Map<String, dynamic>> _historyMap = {};
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();

    // 1. 数据解析
    var rawList = widget.questionsRaw.map((q) => Question.fromMap(q)).toList();

    // 2. ✨ 初始化时强制按 ID 排序，确保“顺序模式”是整齐的
    rawList.sort((a, b) => a.id.compareTo(b.id));

    _allQuestions = rawList;

    // 3. 备份一份有序列表
    _sequentialQuestions = List.from(rawList);

    // 4. 初始化显示列表（默认是顺序的）
    _displayQuestions = List.from(_sequentialQuestions);

    _loadCurrentQuestionState();

    if (_currentMode != ExamMode.memorize) {
      _fetchUserProgress();
    } else {
      _isLoadingProgress = false;
      _isAnswerRevealed = true;
    }
  }

  // --- ✨✨✨ 核心逻辑：切换 顺序/乱序 ✨✨✨ ---
  void _toggleSortOrder() {
    setState(() {
      _isShuffleOn = !_isShuffleOn; // 切换开关状态

      if (_isShuffleOn) {
        // 🔀 开启乱序：打乱 _displayQuestions
        _displayQuestions.shuffle();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔀 已切换为：随机乱序模式 (进度重置到第1题)')),
        );
      } else {
        // 🔢 关闭乱序：恢复成备份的有序列表
        _displayQuestions = List.from(_sequentialQuestions);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔢 已切换为：标准顺序模式 (进度重置到第1题)')),
        );
      }

      // 切换顺序后，为了防止索引错乱，统一回到第一题
      _currentIndex = 0;
      _loadCurrentQuestionState();
    });
  }

  // --- 数据加载与进度管理 ---

  Future<void> _fetchUserProgress() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _displayQuestions.isEmpty) {
      setState(() => _isLoadingProgress = false);
      return;
    }
    List<int> qIds = _allQuestions.map((q) => q.id).toList();
    final data = await _examService.fetchUserProgress(userId: user.id, questionIds: qIds);

    if (mounted) {
      setState(() {
        _historyMap = data;
        _isLoadingProgress = false;

        // ✨ 自动跳转逻辑：只在顺序模式下跳转，乱序下跳转会很奇怪
        if (!_isShuffleOn) {
          int firstUnanswered = -1;
          for (int i = 0; i < _displayQuestions.length; i++) {
            if (!_historyMap.containsKey(_displayQuestions[i].id)) {
              firstUnanswered = i;
              break;
            }
          }
          if (firstUnanswered != -1 && firstUnanswered != 0) {
            _currentIndex = firstUnanswered;
          }
        }
        _loadCurrentQuestionState();
      });
    }
  }

  void _loadCurrentQuestionState() {
    if (_displayQuestions.isEmpty) return;
    Question currentQ = _displayQuestions[_currentIndex];
    _selectedOptionIndex = -1;
    _selectedIndicesSet.clear();

    if (_currentMode == ExamMode.memorize) {
      _isAnswerRevealed = true;
      return;
    }
    if (_historyMap.containsKey(currentQ.id)) {
      _isAnswerRevealed = true;
    } else {
      _isAnswerRevealed = false;
    }
  }

  // --- 答题交互逻辑 ---

  bool _checkIsCorrect() {
    Question q = _displayQuestions[_currentIndex];
    List<int> correctIndices = q.answerIndices;
    if (_selectedIndicesSet.length != correctIndices.length) return false;
    for (int idx in correctIndices) {
      if (!_selectedIndicesSet.contains(idx)) return false;
    }
    return true;
  }

  void _handleOptionTap(int index) {
    if (_currentMode == ExamMode.memorize || _isAnswerRevealed) return;
    Question currentQ = _displayQuestions[_currentIndex];
    setState(() {
      if (currentQ.isMultiSelect) {
        if (_selectedIndicesSet.contains(index)) {
          _selectedIndicesSet.remove(index);
        } else {
          _selectedIndicesSet.add(index);
        }
      } else {
        _selectedOptionIndex = index;
        _selectedIndicesSet = {index};
        if (_currentMode == ExamMode.rapid) {
          _submitAnswer();
        }
      }
    });
  }

  void _submitAnswer() {
    if (_selectedIndicesSet.isEmpty) return;
    bool isCorrect = _checkIsCorrect();
    setState(() {
      _isAnswerRevealed = true;
      _saveProgress(_currentIndex, isCorrect);
      _sessionAttempted++;
      if (isCorrect) _sessionCorrectCount++;
    });

    if (isCorrect && _currentMode == ExamMode.rapid) {
      if (_currentIndex < _displayQuestions.length - 1) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _nextQuestion();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 本套题已完成！')));
      }
    }
  }

  void _nextQuestion() {
    if (_currentIndex >= _displayQuestions.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已经是最后一题了')));
      return;
    }
    setState(() {
      _currentIndex++;
      _loadCurrentQuestionState();
    });
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _loadCurrentQuestionState();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已经是第一题了')));
    }
  }

  Future<void> _saveProgress(int index, bool isCorrect) async {
    final user = Supabase.instance.client.auth.currentUser;
    Question currentQ = _displayQuestions[index];
    setState(() {
      _historyMap[currentQ.id] = {'isCorrect': isCorrect};
    });
    if (user != null) {
      int savedIndex = _selectedIndicesSet.isNotEmpty ? _selectedIndicesSet.first : -1;
      await _examService.saveProgress(
          userId: user.id,
          questionId: currentQ.id,
          isCorrect: isCorrect,
          selectedOptionIndex: savedIndex);
    }
  }

  // --- 辅助功能 ---

  Future<void> _sendMessageToAuthor() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录')));
      return;
    }
    Question currentQ = _displayQuestions[_currentIndex];
    if (currentQ.createdBy == null || currentQ.createdBy == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法给自己或本地题目发信')));
      return;
    }
    final String? message = await showDialog<String>(context: context, builder: (context) => const OwlMessageDialog());
    if (message == null) return;
    try {
      String nickname = user.userMetadata?['display_name'] ?? "神秘智者";
      await _examService.sendOwlMessage(
          senderId: user.id, receiverId: currentQ.createdBy!, senderNickname: nickname,
          groupName: currentQ.groupName ?? "未知", messageContent: message, questionContent: currentQ.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已发送！✅'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
    }
  }

  void _showQuestionGrid() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return QuestionGrid(
          questions: _displayQuestions,
          historyMap: _historyMap,
          currentIndex: _currentIndex,
          onJumpToQuestion: (index) {
            setState(() {
              _currentIndex = index;
              _loadCurrentQuestionState();
            });
            Navigator.pop(context);
          },
          onResetProgress: () async {
            Navigator.pop(context);
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) {
              List<int> qIds = _allQuestions.map((q) => q.id).toList();
              await _examService.resetProgress(userId: user.id, questionIds: qIds);
              setState(() {
                _historyMap.clear();
                _currentIndex = 0;
                _sessionCorrectCount = 0;
                _sessionAttempted = 0;
                _loadCurrentQuestionState();
              });
            }
          },
        );
      },
    );
  }

  // --- ✨✨✨ 极其简洁的 UI 构建 ✨✨✨ ---
  @override
  Widget build(BuildContext context) {
    if (_displayQuestions.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('无题目')), body: const Center(child: Text("没有题目")));
    }

    Question currentQ = _displayQuestions[_currentIndex];

    // 计算统计数据
    int completedCount = _historyMap.length;
    int remainingCount = _displayQuestions.length - completedCount;
    int totalCorrect = _historyMap.values.where((record) => record['isCorrect'] == true).length;
    String accuracy = completedCount == 0
        ? "0%"
        : "${((totalCorrect / completedCount) * 100).toStringAsFixed(0)}%";

    bool showSubmitBtn = !_isAnswerRevealed && (currentQ.isMultiSelect || _currentMode == ExamMode.practice);

    return Scaffold(
      // 1. 顶部：交给 ExamAppBar 控制
      appBar: ExamAppBar(
        currentIndex: _currentIndex,
        totalCount: _displayQuestions.length,
        isShuffleOn: _isShuffleOn,        // 传入当前是否乱序
        currentMode: _currentMode,
        onToggleSort: _toggleSortOrder,   // 传入切换排序的回调
        onSendMessage: _sendMessageToAuthor,
        onShowGrid: _showQuestionGrid,
        onModeChanged: (mode) {
          setState(() {
            _currentMode = mode;
            _loadCurrentQuestionState();
          });
        },
      ),

      body: Column(
        children: [
          if (_isLoadingProgress) const LinearProgressIndicator(),

          // 进度条 (保留在这里，或者也可以移入 AppBar 的 bottom 属性)
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _displayQuestions.length,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
          ),

          // 2. 中间：交给 ExamQuestionView 显示题目
          Expanded(
            child: ExamQuestionView(
              question: currentQ,
              currentOptions: currentQ.optionsList,
              selectedIndices: _selectedIndicesSet,
              isAnswerRevealed: _isAnswerRevealed,
              showSubmitBtn: showSubmitBtn,
              onNextQuestion: _nextQuestion,
              onPrevQuestion: _prevQuestion,
              onSubmitAnswer: _submitAnswer,
              onOptionTap: _handleOptionTap,
            ),
          ),

          // 3. 底部：交给 ExamStatsBar 显示数据
          ExamStatsBar(
              completedCount: completedCount,
              totalCount: _displayQuestions.length,
              remainingCount: remainingCount,
              accuracy: accuracy
          ),
        ],
      ),
    );
  }
}