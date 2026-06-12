import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 Firestoreを使うために必要

class TodayActivityScreen extends StatefulWidget {
  const TodayActivityScreen({super.key});

  @override
  State<TodayActivityScreen> createState() => _TodayActivityScreenState();
}

class _TodayActivityScreenState extends State<TodayActivityScreen> {
  // 👈 入力された文字をキャッチするためのコントローラーを用意
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  // 👈 データをFirestoreに保存する関数（関数名の前に async をつけます）
  Future<void> _saveActivity() async {
    // 入力欄が空っぽの場合は保存しない
    if (_targetController.text.isEmpty && _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予定が入力されていません')),
      );
      return;
    }

    try {
      // Firestoreの「activities」という名前の箱（コレクション）にデータを保存します
      await FirebaseFirestore.instance.collection('activities').add({
        'target': _targetController.text,       // その日の目標
        'content': _contentController.text,     // 活動内容
        'result': _resultController.text,       // 実績結果
        'createdAt': Timestamp.now(),           // 保存した日時
      });

      // 保存できたら入力欄をきれいに空っぽにする
      _targetController.clear();
      _contentController.clear();
      _resultController.clear();

      // 画面に成功メッセージを出す
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 データをデータベースに保存しました！')),
        );
      }
    } catch (e) {
      // 万が一エラーが起きた場合
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  // 画面が閉じるときにコントローラーを破棄する（お作法）
  @override
  void dispose() {
    _targetController.dispose();
    _contentController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の活動部屋', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ③ 日々の活動予定入力セクション ---
            const Text('📝 今日の予定入力', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 8),
            TextField(
              controller: _targetController, // 👈 コントローラーを紐付け
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'その日の目標（例: 英語を1時間勉強する）',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController, // 👈 コントローラーを紐付け
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '活動内容（具体的に取り組むこと）',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saveActivity, // 👈 ボタンを押したときに上の保存関数を実行！
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              icon: const Icon(Icons.check),
              label: const Text('予定を確定する'),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(thickness: 2),
            ),

            // --- ④ 日々の活動実績入力セクション ---
            const Text('🏆 今日の実績入力', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 8),
            TextField(
              controller: _resultController, // 👈 コントローラーを紐付け
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'その日の結果（達成できたこと、反省など）',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _saveActivity, // 👈 実績入力のボタンでも同じ保存関数を動かします
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  icon: const Icon(Icons.send),
                  label: const Text('実績を保存する'),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.blue),
                  onPressed: () {},
                  tooltip: 'SNSにシェア',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}