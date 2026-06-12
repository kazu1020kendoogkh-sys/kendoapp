import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodayActivityScreen extends StatefulWidget {
  const TodayActivityScreen({super.key});

  @override
  State<TodayActivityScreen> createState() => _TodayActivityScreenState();
}

class _TodayActivityScreenState extends State<TodayActivityScreen> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  DateTime _inputDate = DateTime.now();
  
  // 👈 現在編集（実績入力を）しているデータのFirestore上のID（nullなら新規作成）
  String? _selectedActivityId;

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _inputDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2028),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.teal, onPrimary: Colors.white, onSurface: Colors.black87),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _inputDate) {
      setState(() {
        _inputDate = picked;
        // 日付を変えたら、その日の新規入力モードにするため選択をクリア
        _clearSelection();
      });
    }
  }

  // フォームの入力内容を綺麗にクリアする関数
  void _clearSelection() {
    setState(() {
      _selectedActivityId = null;
      _targetController.clear();
      _contentController.clear();
      _resultController.clear();
    });
  }

  // 👈 【新機能】登録済みの予定をタップした時に、フォームにデータを読み込む関数
  void _selectActivity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _selectedActivityId = doc.id;
      _targetController.text = data['target'] ?? '';
      _contentController.text = data['content'] ?? '';
      _resultController.text = data['result'] ?? '';
      if (data['createdAt'] != null) {
        _inputDate = (data['createdAt'] as Timestamp).toDate();
      }
    });
  }

  // 👈 予定の新規保存、および実績の「追記（更新）」を行うメイン関数
  Future<void> _saveActivity() async {
    if (_targetController.text.isEmpty && _contentController.text.isEmpty && _resultController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('入力されていません')));
      return;
    }

    try {
      final int year = _inputDate.year;
      final int month = _inputDate.month;
      final int day = _inputDate.day;
      
      final int firstDayOfWeek = DateTime(year, month, 1).weekday;
      final int weekNum = ((day + firstDayOfWeek - 2) / 7).floor() + 1;
      final String weekLabel = '第$weekNum週';

      final now = DateTime.now();
      final savedDateTime = DateTime(year, month, day, now.hour, now.minute, now.second);

      final Map<String, dynamic> activityData = {
        'target': _targetController.text,
        'content': _contentController.text,
        'result': _resultController.text, // 実績入力欄の中身
        'year': year,
        'month': month,
        'week': weekLabel,
        'day': day,
      };

      if (_selectedActivityId == null) {
        // 🆕 予定の新規追加の場合
        activityData['createdAt'] = Timestamp.fromDate(savedDateTime);
        await FirebaseFirestore.instance.collection('activities').add(activityData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 新しい予定を確定しました！')));
      } else {
        // 🔄 既存の予定に「実績を追記（更新）」する場合
        await FirebaseFirestore.instance.collection('activities').doc(_selectedActivityId).update(activityData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🏆 実績結果を保存（合体）しました！')));
      }

      // 保存後はフォームをクリアし、日付を今日に戻す
      _clearSelection();
      setState(() {
        _inputDate = DateTime.now();
      });

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    _contentController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String dateString = "${_inputDate.year}/${_inputDate.month.toString().padLeft(2, '0')}/${_inputDate.day.toString().padLeft(2, '0')}";

    // 選択された日付の「0:00 〜 23:59」までのデータをリアルタイム取得するためのクエリ
    final startOfDay = DateTime(_inputDate.year, _inputDate.month, _inputDate.day, 0, 0, 0);
    final endOfDay = DateTime(_inputDate.year, _inputDate.month, _inputDate.day, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の活動部屋', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 📅 日付選択ボックス
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text('$dateString の活動', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _pickDate(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    child: const Text('日付変更'),
                  ),
                ],
              ),
            ),
          ),

          // 🔍 【新機能】その日に登録されている予定の一覧（選択用エリア）
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text('👇 実績を入力したい予定を選んでください', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('activities')
                          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
                          .where('createdAt', isLessThanOrEqualTo: endOfDay)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('この日の予定はまだありません。下のフォームから新規登録できます。', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center));
                        }
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final target = data['target'] ?? '（目標未入力）';
                            final hasResult = data['result'] != null && data['result'].toString().isNotEmpty;
                            final isCurrent = _selectedActivityId == doc.id;

                            return Card(
                              color: isCurrent ? Colors.teal[50] : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: isCurrent ? Colors.teal : Colors.grey[300]!, width: isCurrent ? 1.5 : 1),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(target, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                                trailing: hasResult 
                                    ? const Icon(Icons.check_circle, color: Colors.orange) // 実績入力済み
                                    : const Icon(Icons.radio_button_unchecked, color: Colors.grey), // 予定のみ
                                onTap: () => _selectActivity(doc),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 24, thickness: 1),

          // 📝 入力・編集フォームエリア
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedActivityId == null ? '📝 予定の新規入力' : '🏆 選んだ予定に実績を入力中',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedActivityId == null ? Colors.teal : Colors.orange[800]),
                      ),
                      if (_selectedActivityId != null)
                        TextButton.icon(
                          onPressed: _clearSelection,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('新規入力に戻る', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                        )
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetController,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'その日の目標（例: 英語を1時間勉強する）'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    maxLines: 2,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '活動内容（具体的に取り組むこと）'),
                  ),
                  const SizedBox(height: 12),
                  
                  // 実績入力欄
                  TextField(
                    controller: _resultController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'その日の結果（達成できたこと、反省など）',
                      focusedBorder: _selectedActivityId != null 
                          ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saveActivity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedActivityId == null ? Colors.teal : Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(_selectedActivityId == null ? Icons.check : Icons.send),
                      label: Text(_selectedActivityId == null ? '予定を確定する' : '実績を保存（予定と合体）する', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}