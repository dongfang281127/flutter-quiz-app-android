import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  bool _isLoading = false;
  final TextEditingController _groupNameCtrl = TextEditingController();

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  /// ✨✨✨ 智能解析单行数据 (升级版) ✨✨✨
  /// 完美支持：
  /// 1. 单列选项 (e.g. "选项")
  /// 2. 多列选项 (e.g. "A", "B" 或 "选项A", "选项B")
  /// 3. 各种答案表头 (e.g. "答案", "我的答案", "Answer")
  Map<String, dynamic>? _smartParseRow(List<dynamic> row, List<dynamic> headers, String userGroupName, String authorName) {
    if (row.isEmpty) return null;

    // 1. 建立表头索引 (转小写，去空格，防止格式差异)
    Map<String, int> headerMap = {};
    for (int i = 0; i < headers.length; i++) {
      String hStr = headers[i]?.toString() ?? "";
      headerMap[hStr.trim().toLowerCase()] = i;
    }

    // 辅助函数：根据可能的表头名列表，查找对应单元格的内容
    String getValue(List<String> possibleNames) {
      for (String name in possibleNames) {
        // 既然我们存的是小写，查询时也要转小写
        String lowerName = name.toLowerCase();
        if (headerMap.containsKey(lowerName)) {
          int index = headerMap[lowerName]!;
          if (index < row.length) {
            var val = row[index];
            return val?.toString().trim() ?? "";
          }
        }
      }
      return "";
    }

    // --- A. 找题目 ---
    String question = getValue([
      'question', '题目', 'questions', 'title', '题干', 'question text'
    ]);
    if (question.isEmpty) return null; // 没题目就跳过

    // --- B. 找选项 (双重策略) ---
    String optionsRaw = "";

    // 策略1：先找是否存在“单列选项” (比如表头叫 "选项" 或 "Options")
    // 注意：有时候表头存在，但这一行内容是空的，所以要 check .isNotEmpty
    String singleCol = getValue(['options', '选项', 'option', 'all options']);

    if (singleCol.isNotEmpty) {
      // 如果找到了单列内容，直接用
      optionsRaw = singleCol;
    } else {
      // 策略2：如果单列没内容，去尝试找“分列选项” (A, B, C...)
      List<String> merged = [];

      // 这里的列表涵盖了你的截图情况：'a', '选项a', 'option a'
      String optA = getValue(['a', 'option a', '选项a', 'option_a', '选项 a']);
      String optB = getValue(['b', 'option b', '选项b', 'option_b', '选项 b']);
      String optC = getValue(['c', 'option c', '选项c', 'option_c', '选项 c']);
      String optD = getValue(['d', 'option d', '选项d', 'option_d', '选项 d']);
      String optE = getValue(['e', 'option e', '选项e', 'option_e', '选项 e']);

      if (optA.isNotEmpty) merged.add(optA);
      if (optB.isNotEmpty) merged.add(optB);
      if (optC.isNotEmpty) merged.add(optC);
      if (optD.isNotEmpty) merged.add(optD);
      if (optE.isNotEmpty) merged.add(optE);

      if (merged.isNotEmpty) {
        // 用 " | " 拼接，适配你的 QuestionModel
        optionsRaw = merged.join(" | ");
      }
    }

    // --- C. 找答案 ---
    // 涵盖了截图里的 "我的答案"
    String answer = getValue([
      'answer', '答案', 'correct answer', '正确答案', '我的答案', 'true answer'
    ]);
    // 清理答案格式 (去掉空格、逗号，转大写)
    answer = answer.replaceAll(RegExp(r'[,，\s\.]'), '').toUpperCase();

    // --- D. 其他字段 ---
    String groupName = userGroupName;

    return {
      'question': question,
      'options': optionsRaw,
      'answer': answer,
      'group_name': groupName,
      'created_by': Supabase.instance.client.auth.currentUser?.id,
      'author_name': authorName,
    };
  }

  Future<void> _pickFile() async {
    String inputName = _groupNameCtrl.text.trim();
    if (inputName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 请先给题库起个名字'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 获取真实昵称
    final user = Supabase.instance.client.auth.currentUser;
    String currentAuthorName = "神秘巫师";

    if (user != null && user.userMetadata != null) {
      final meta = user.userMetadata!;
      currentAuthorName = meta['display_name'] ??
          meta['name'] ??
          meta['full_name'] ??
          meta['user_name'] ??
          meta['nickname'] ??
          "神秘巫师";
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        List<Map<String, dynamic>> importedQuestions = [];
        Set<String> uniqueCheck = {};

        var decoder = SpreadsheetDecoder.decodeBytes(file.bytes!);

        if (decoder.tables.isNotEmpty) {
          var sheetName = decoder.tables.keys.first;
          var table = decoder.tables[sheetName];

          if (table != null && table.rows.isNotEmpty) {
            List<dynamic> headers = table.rows[0];

            for (var i = 1; i < table.rows.length; i++) {
              // 调用智能解析
              var parsed = _smartParseRow(table.rows[i], headers, inputName, currentAuthorName);

              if (parsed != null) {
                // 简单的去重逻辑
                String signature = "${parsed['question']}-${parsed['answer']}";
                if (!uniqueCheck.contains(signature)) {
                  importedQuestions.add(parsed);
                  uniqueCheck.add(signature);
                }
              }
            }
          }
        }

        if (importedQuestions.isNotEmpty) {
          await Supabase.instance.client.from('questions').insert(importedQuestions);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 成功创建题库《$inputName》，包含 ${importedQuestions.length} 道题目！'),
                backgroundColor: Colors.green,
              ),
            );
            if (Navigator.canPop(context)) Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ 未解析到有效题目，请检查 Excel 表头是否包含“题目”和“答案”')),
            );
          }
        }
      }
    } catch (e) {
      print("Import Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入出错: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(title: const Text("创建新题库")),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.note_add, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 30),

                  TextField(
                    controller: _groupNameCtrl,
                    decoration: InputDecoration(
                      labelText: "题库名称",
                      hintText: "例如：医学期末复习",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.edit),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "支持两种 Excel 格式：\n1. 题目 | 选项 | 答案 (单列选项)\n2. 题目 | 选项A | 选项B... | 答案 (多列选项)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 40),

                  _isLoading
                      ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("正在处理数据..."),
                    ],
                  )
                      : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("选择 Excel 并创建"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}