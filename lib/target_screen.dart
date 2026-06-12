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

    // 大きめのヘッダータイトル作成
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
        // 固定ヘッダー
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

        // リスト表示エリア
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

              // 👈 【超重要】データをグループ分けする処理
              // 週間目標なら「〇年〇月」、月間目標なら「〇年」をキー（親玉）にして、データを分類します。
              Map<String, List<DocumentSnapshot>> groupedData = {};
              
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                String groupKey = '';
                
                if (type == '週間') {
                  // 週間目標は「年・月単位」でまとめる
                  groupKey = '${data['year'] ?? 0}年 ${data['month'] ?? 0}月';
                } else if (type == '月間') {
                  // 月間目標は「年単位」でまとめる
                  groupKey = '${data['year'] ?? 0}年';
                } else {
                  // 年間目標はまとめる必要がないので空のまま
                  groupKey = '';
                }

                if (!groupedData.containsKey(groupKey)) {
                  groupedData[groupKey] = [];
                }
                groupedData[groupKey]!.add(doc);
              }

              // 年間目標の場合は、今まで通りシンプルに並べる
              if (type == '年間' || groupedData.containsKey('')) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) => _buildTargetTile(docs[index], type),
                );
              }

              // 👈 月間・週間目標の場合は、グループ化された塊ごとにカードを作って表示
              final groupKeys = groupedData.keys.toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupKeys.length,
                itemBuilder: (context, groupIndex) {
                  final groupName = groupKeys[groupIndex];
                  final groupDocs = groupedData[groupName]!;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.teal, width: 1.5), // グループの枠線を太めにして目立たせる
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📦 グループのデカ見出し（「2026年」や「2026年 6月」など）
                          Row(
                            children: [
                              Icon(type == '週間' ? Icons.date_range : Icons.folder, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                groupName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.teal, thickness: 1),
                          const SizedBox(height: 8),
                          
                          // 📜 そのグループに所属する目標たちを縦に並べる
                          Column(
                            children: groupDocs.map((doc) => _buildTargetTile(doc, type)).toList(),
                          ),
                        ],
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

// ⭕ 「〇月の目標」や「第1週」をカードの上側にのせる修正版
  Widget _buildTargetTile(DocumentSnapshot doc, String type) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? '（未入力）';
    final monthVal = data['month'] ?? 0;
    final week = data['week'] ?? '';

    // --- 👈 1. カードの上に載せるラベルの文字を組み立てる ---
    String topCardLabel = '';
    if (type == '月間' && monthVal > 0) {
      topCardLabel = '$monthVal月の目標';
    } else if (type == '週間' && week.isNotEmpty) {
      topCardLabel = week; // 「第1週」など
    }

    // 2. カード本体（中身はタイトルだけにスッキリさせました）
    Widget cardWidget = Card(
      margin: const EdgeInsets.only(bottom: 12), // カードの下側に隙間をあける
      color: Colors.grey[50], // ほんのりグレーの背景で上品に
      elevation: 0, // 枠線フォルダーの中なので影を無くしてスッキリ
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!), // 軽い枠線
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          type == '週間' ? Icons.looks_one : (type == '月間' ? Icons.star_half : Icons.star),
          color: Colors.teal[400],
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () => FirebaseFirestore.instance.collection('targets').doc(doc.id).delete(),
        ),
      ),
    );

    // --- 👈 3. ラベルがある場合は、Columnを使ってカードの上に配置する ---
    if (topCardLabel.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 4, bottom: 2), // ラベルの位置調整
            child: Text(
              topCardLabel,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: Colors.teal[700], // 剣道アプリのテーマカラーに合わせる
              ),
            ),
          ),
          cardWidget, // ラベルのすぐ下にカードを表示
        ],
      );
    }

    // 年間目標など、上側ラベルがない場合はカードだけをそのまま返す
    return cardWidget;
  }
}