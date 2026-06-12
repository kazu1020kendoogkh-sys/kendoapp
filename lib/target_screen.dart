import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TargetScreen extends StatefulWidget {
  const TargetScreen({super.key});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  void _showAddTargetDialog(BuildContext context, String type) {
    final TextEditingController targetController = TextEditingController();
    
    int dialogYear = selectedYear == 0 ? DateTime.now().year : selectedYear;
    int dialogMonth = selectedMonth == 0 ? DateTime.now().month : selectedMonth;
    String dialogWeek = '第1週';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('$type目標の追加', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: Text('対象年', style: TextStyle(fontSize: 12))),
                    DropdownButton<int>(
                      isExpanded: true,
                      value: dialogYear,
                      items: [2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('${y}年'))).toList(),
                      onChanged: (val) => setDialogState(() => dialogYear = val!),
                    ),
                    const SizedBox(height: 10),
                    if (type != '年間') ...[
                      const Align(alignment: Alignment.centerLeft, child: Text('対象月', style: TextStyle(fontSize: 12))),
                      DropdownButton<int>(
                        isExpanded: true,
                        value: dialogMonth,
                        items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text('${m}月'))).toList(),
                        onChanged: (val) => setDialogState(() => dialogMonth = val!),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (type == '週間') ...[
                      const Align(alignment: Alignment.centerLeft, child: Text('対象週', style: TextStyle(fontSize: 12))),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: dialogWeek,
                        items: ['第1週', '第2週', '第3週', '第4週', '第5週']
                            .map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                        onChanged: (val) => setDialogState(() => dialogWeek = val!),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: targetController,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '目標内容'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (targetController.text.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('targets').add({
                        'title': targetController.text,
                        'type': type,
                        'year': dialogYear,
                        'month': type == '年間' ? 0 : dialogMonth,
                        'week': type == '週間' ? dialogWeek : '',
                        'createdAt': Timestamp.now(),
                      });
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('目標設定部屋', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            DropdownButton<int>(
              dropdownColor: Colors.teal,
              value: selectedYear,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              underline: Container(),
              items: [
                const DropdownMenuItem(value: 0, child: Text('すべての年')),
                ...[2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('${y}年'))),
              ],
              onChanged: (val) => setState(() => selectedYear = val!),
            ),
            DropdownButton<int>(
              dropdownColor: Colors.teal,
              value: selectedMonth,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              underline: Container(),
              items: [
                const DropdownMenuItem(value: 0, child: Text('すべての月')),
                ...List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text('${m}月'))),
              ],
              onChanged: (val) => setState(() => selectedMonth = val!),
            ),
            const SizedBox(width: 10),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [Tab(text: '年間'), Tab(text: '月間'), Tab(text: '週間')],
          ),
        ),
        body: TabBarView(
          children: [
            TargetList(type: '年間', year: selectedYear, month: 0),
            TargetList(type: '月間', year: selectedYear, month: selectedMonth),
            TargetList(type: '週間', year: selectedYear, month: selectedMonth),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            backgroundColor: Colors.teal,
            onPressed: () {
              final tabIndex = DefaultTabController.of(context).index;
              final types = ['年間', '月間', '週間'];
              _showAddTargetDialog(context, types[tabIndex]);
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class TargetList extends StatelessWidget {
  final String type;
  final int year;
  final int month;
  const TargetList({super.key, required this.type, required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('targets').where('type', isEqualTo: type);

    if (year != 0) {
      query = query.where('year', isEqualTo: year);
    }

    if (type != '年間' && month != 0) {
      query = query.where('month', isEqualTo: month);
    }

    // --- 👈 1. ページ最上部に表示する大きめのタイトル文字を作成 ---
    String headerTitle = '';
    headerTitle += '$type目標';
    if (year == 0) {
      headerTitle += '（全期間）';
    } else {
      headerTitle += '（${year}年）';
    }

    if (type != '年間') {
      if (month == 0) {
        headerTitle += '（全ての月）';
      } else {
        headerTitle += '（${month}月）';
      }
    }    

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 👈 2. 大きめのヘッダー表示エリアを追加 ---
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                headerTitle,
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(thickness: 1, color: Colors.black12), // 下線をつけてスッキリさせる
        ),

        // 3. 残りのスペースにリストを表示（Expandedで包む）
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('エラーが発生しました'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('目標は未設定です', style: TextStyle(color: Colors.grey[600])));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  
                  String topLabel = '';
                  if (year == 0 && data['year'] != null) {
                    topLabel += '${data['year']}年 ';
                  }
                  if (month == 0 && data['month'] != null && data['month'] != 0) {
                    topLabel += '${data['month']}月 ';
                  }

                  Widget cardWidget = Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(type == '週間' ? Icons.looks_one : Icons.star, color: Colors.teal),
                      title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: type == '週間' && data['week'] != null && data['week'] != ''
                          ? Text(data['week'])
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance.collection('targets').doc(doc.id).delete(),
                      ),
                    ),
                  );

                  if (topLabel.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4, top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              topLabel.trim(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ),
                        ),
                        cardWidget,
                      ],
                    );
                  }

                  return cardWidget;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}