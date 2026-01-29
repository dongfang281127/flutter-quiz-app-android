class Question {
  final int id;
  final String text;
  final String optionsRaw;
  final String answer; // 比如 "A" 或 "ABD"
  final String? createdBy;
  final String? groupName;

  const Question({
    required this.id,
    required this.text,
    required this.optionsRaw,
    required this.answer,
    this.createdBy,
    this.groupName,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int,
      text: map['question']?.toString() ?? '',
      optionsRaw: map['options']?.toString() ?? '',
      answer: map['answer']?.toString().toUpperCase().replaceAll(' ', '') ?? '', // 去空格转大写
      createdBy: map['created_by']?.toString(),
      groupName: map['group_name']?.toString(),
    );
  }

  List<String> get optionsList {
    if (optionsRaw.isEmpty) return [];
    return optionsRaw.split(" | ");
  }

  // ✨✨✨ 新增：判断是否为多选 ✨✨✨
  // 如果答案长度大于1 (比如 "AB")，或者是 "ALL" 之类的，就是多选
  bool get isMultiSelect => answer.length > 1;

  // ✨✨✨ 新增：获取多选答案的索引列表 ✨✨✨
  // 比如答案是 "AC"，返回 [0, 2]
  List<int> get answerIndices {
    List<int> indices = [];
    if (answer.isEmpty) return indices;
    
    for (int i = 0; i < answer.length; i++) {
      int code = answer.codeUnitAt(i);
      // A=65, B=66...
      if (code >= 65 && code <= 90) {
        indices.add(code - 65);
      }
    }
    return indices;
  }
}