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
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: Colors.teal),
              const SizedBox(width: 8),
              Text(headerTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(thickness: 1, color: Colors.black12),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('エラーが発生しました'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('目標は未設定です', style: TextStyle(color: Colors.grey[600])));
              }

              final docs = snapshot.data!.docs;
              Map<String, List<DocumentSnapshot>> groupedData = {};
              
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                String groupKey = '';
                if (type == '週間') {
                  groupKey = '${data['year'] ?? 0}年 ${data['month'] ?? 0}月';
                } else if (type == '月間') {
                  groupKey = '${data['year'] ?? 0}年';
                } else {
                  groupKey = '';
                }

                if (!groupedData.containsKey(groupKey)) {
                  groupedData[groupKey] = [];
                }
                groupedData[groupKey]!.add(doc);
              }

              if (type == '年間' || groupedData.containsKey('')) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) => _buildTargetTile(docs[index], type),
                );
              }

              final groupKeys = groupedData.keys.toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: groupKeys.length,
                itemBuilder: (context, groupIndex) {
                  final groupName = groupKeys[groupIndex];
                  final groupDocs = groupedData[groupName]!;

                  // --- 👈 ここから「開閉する外枠」の作成 ---
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias, // 角丸からはみ出ないように
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.teal, width: 1.5),
                    ),
                    child: Theme(
                      // タップした時の変な色を消すための設定
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        // 最初から開いておくかどうか（最新のグループだけ開いておくと親切）
                        initiallyExpanded: false, 
                        backgroundColor: Colors.teal.withOpacity(0.02),
                        collapsedBackgroundColor: Colors.white,
                        title: Text(
                          groupName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        leading: Icon(type == '週間' ? Icons.date_range : Icons.folder, color: Colors.teal),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        // 中身（目標カードたち）
                        children: groupDocs.map((doc) => _buildTargetTile(doc, type)).toList(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTargetTile(DocumentSnapshot doc, String type) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? '（未入力）';
    final monthVal = data['month'] ?? 0;
    final week = data['week'] ?? '';

    String topCardLabel = '';
    if (type == '月間' && monthVal > 0) {
      topCardLabel = '$monthVal月の目標';
    } else if (type == '週間' && week.isNotEmpty) {
      topCardLabel = week;
    }

    Widget cardWidget = Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          type == '週間' ? Icons.looks_one : (type == '月間' ? Icons.star_half : Icons.star),
          color: Colors.teal[400],
          size: 20,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
          onPressed: () => FirebaseFirestore.instance.collection('targets').doc(doc.id).delete(),
        ),
      ),
    );

    if (topCardLabel.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 2, bottom: 2),
            child: Text(
              topCardLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[700]),
            ),
          ),
          cardWidget,
        ],
      );
    }
    return cardWidget;
  }
}