import 'package:flutter/material.dart';

class OwlMessageDialog extends StatefulWidget {
  const OwlMessageDialog({super.key});

  @override
  State<OwlMessageDialog> createState() => _OwlMessageDialogState();
}

class _OwlMessageDialogState extends State<OwlMessageDialog> {
  // 控制器现在藏在这个组件内部，外部不需要操心了
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose(); // 记得销毁，防止内存泄漏
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('给作者留言'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "不吝赐教\n有什么思绪或建议，请在此落笔...",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _msgCtrl,
            maxLines: 3,
            autofocus: true, // 打开弹窗自动聚焦键盘
            decoration: const InputDecoration(
              hintText: "在此输入内容...",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 点击取消，返回 null
            Navigator.of(context).pop(null);
          },
          child: const Text('取消'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            String text = _msgCtrl.text.trim();
            if (text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('不能发送空消息哦')),
              );
              return;
            }
            // 点击发送，把输入的文字传回去
            Navigator.of(context).pop(text);
          },
          icon: const Icon(Icons.send, size: 16),
          label: const Text('发送'),
        ),
      ],
    );
  }
}