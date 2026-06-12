import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedYear = DateTime.now().year;   
  int _selectedMonth = DateTime.now().month; 
  DateTime? _selectedDate;                    

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(_selectedYear, _selectedMonth == 0 ? 1 : _selectedMonth, 1),
      firstDate: DateTime(2024),
      lastDate: DateTime(2028),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.teal)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedYear = picked.year;   
        _selectedMonth = picked.month; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String headerTitleText = '';
    if (_selectedDate != null) {
      headerTitleText = DateFormat('yyyy年MM月dd日').format(_selectedDate!);
    } else {
      String yText = _selectedYear == 0 ? '全期間' : '${_selectedYear}年';
      String mText = _selectedMonth == 0 ? 'すべての月' : '${_selectedMonth}月';
      headerTitleText = _selectedYear == 0 && _selectedMonth == 0 ? '全期間' : '$yText $mText';
    }

    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('活動参照部屋', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            DropdownButton<int>(
              dropdownColor: Colors.teal,
              value: _selectedYear,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              underline: Container(),
              items: [
                const DropdownMenuItem(value: 0, child: Text('すべての年', style: TextStyle(color: Colors.white))),
                ...[2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('${y}年', style: const TextStyle(color: Colors.white)))),
              ],
              onChanged: (val) => setState(() { _selectedYear = val!; _selectedDate = null; }),
            ),
            DropdownButton<int>(
              dropdownColor: Colors.teal,
              value: _selectedMonth,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              underline: Container(),
              items: [
                const DropdownMenuItem(value: 0, child: Text('すべての月', style: TextStyle(color: Colors.white))),
                ...List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text('${m}月', style: const TextStyle(color: Colors.white)))),
              ],
              onChanged: (val) => setState(() { _selectedMonth = val!; _selectedDate = null; }),
            ),
            IconButton(
              icon: Icon(_selectedDate != null ? Icons.calendar_today : Icons.calendar_month),
              onPressed: () => _pickDate(context),
            ),
            if (_selectedYear != 0 || _selectedMonth != 0 || _selectedDate != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() {
                  _selectedYear = DateTime.now().year;
                  _selectedMonth = DateTime.now().month;
                  _selectedDate = null;
                }),
              ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: '日単位'), 
              Tab(text: '週単位'),
              Tab(text: '月単位'), 
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.teal.withOpacity(0.06), 
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Text(
                '📁 $headerTitleText の活動報告を表示中',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  HistoryList(unit: '日', filterYear: _selectedYear, filterMonth: _selectedMonth, filterDate: _selectedDate),
                  HistoryList(unit: '週', filterYear: _selectedYear, filterMonth: _selectedMonth, filterDate: _selectedDate),
                  HistoryList(unit: '月', filterYear: _selectedYear, filterMonth: _selectedMonth, filterDate: _selectedDate), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryList extends StatelessWidget {
  final String unit; final int filterYear; final int filterMonth; final DateTime? filterDate;
  const HistoryList({super.key, required this.unit, required this.filterYear, required this.filterMonth, this.filterDate});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('activities');

    if (filterDate != null) {
      final startOfDay = DateTime(filterDate!.year, filterDate!.month, filterDate!.day, 0, 0, 0);
      final endOfDay = DateTime(filterDate!.year, filterDate!.month, filterDate!.day, 23, 59, 59);
      query = query.where('createdAt', isGreaterThanOrEqualTo: startOfDay).where('createdAt', isLessThanOrEqualTo: endOfDay);
    } else {
      if (filterYear != 0) query = query.where('year', isEqualTo: filterYear);
      if (filterMonth != 0) query = query.where('month', isEqualTo: filterMonth);
      query = query.orderBy('createdAt', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('エラー: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('該当する活動記録はありません。', style: TextStyle(color: Colors.grey)));

        final docs = snapshot.data!.docs;
        final sortedDocs = List<DocumentSnapshot>.from(docs);
        if (filterDate != null) {
          sortedDocs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
        }

        // 🗺️ 1. まず全データを【月ごと】のグループ（Map）に分配する（すべてのタブ共通）
        Map<String, List<DocumentSnapshot>> monthlyGroupedData = {};
        for (var doc in sortedDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final int y = data['year'] ?? 0;
          final int m = data['month'] ?? 0;
          String monthKey = '${y}年 ${m.toString().padLeft(2, '0')}月';
          if (y == 0 || m == 0) monthKey = '日付未設定の月';

          if (!monthlyGroupedData.containsKey(monthKey)) {
            monthlyGroupedData[monthKey] = [];
          }
          monthlyGroupedData[monthKey]!.add(doc);
        }

        // 月のリストを最新順（降順）にソート
        final monthKeys = monthlyGroupedData.keys.toList();
        monthKeys.sort((a, b) => b.compareTo(a));   

        // 🧱 全てのタブで共通して、外枠に「月のアコーディオン」を表示する
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: monthKeys.length,
          itemBuilder: (context, monthIndex) {
            final monthName = monthKeys[monthIndex];
            final monthDocs = monthlyGroupedData[monthName]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), 
                side: const BorderSide(color: Colors.teal, width: 2.0) // 月アコーディオンを少し太めの枠線にして目立たせる
              ),
              child: ExpansionTile(
                initiallyExpanded: false, // デフォルトで開いた状態
                backgroundColor: Colors.teal.withOpacity(0.01),
                leading: const Icon(Icons.calendar_month, color: Colors.teal, size: 24),
                title: Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                
                // 📂 各タブに応じて、月フォルダの中身（children）の出し方を変える
                children: [
                  if (unit == '日' || unit == '月')
                    // 🗓️ 日単位・月単位の場合は、そのまま活動カードのリストを敷き詰める
                    ...monthDocs.map((doc) => _buildActivityCard(doc)).toList()
                  
                  else if (unit == '週')
                    // 🔄 週単位の場合は、月フォルダの中でさらに「週アコーディオン」にグループ化する
                    ..._buildWeeklyWidgetsInMonth(monthDocs)
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🛠️ 【週単位専用ヘルパー】渡された月データの中からさらに週ごとにグループ化したアコーディオンを作る
  List<Widget> _buildWeeklyWidgetsInMonth(List<DocumentSnapshot> monthDocs) {
    Map<String, List<DocumentSnapshot>> weeklyGroupedData = {};
    
    for (var doc in monthDocs) {
      final data = doc.data() as Map<String, dynamic>;
      String weekKey = data['week'] != null && data['week'] != '' ? data['week'] : '週未設定';
      if (!weeklyGroupedData.containsKey(weekKey)) {
        weeklyGroupedData[weekKey] = [];
      }
      weeklyGroupedData[weekKey]!.add(doc);
    }

    // 第1週〜第5週が綺麗に上から並ぶようにソート
    final weekKeys = weeklyGroupedData.keys.toList()..sort((a, b) => a.compareTo(b));

    return weekKeys.map((weekName) {
      final weekDocs = weeklyGroupedData[weekName]!;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 10, top: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), 
          side: BorderSide(color: Colors.teal.withOpacity(0.3), width: 1)
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: const Icon(Icons.view_week, color: Colors.teal, size: 20),
          title: Text(weekName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 14)),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          children: weekDocs.map((doc) => _buildActivityCard(doc)).toList(),
        ),
      );
    }).toList();
  }

  // 📝 各活動カードのレイアウト（変更なし・日付最上部キープ）
  Widget _buildActivityCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final target = data['target'] ?? '（目標未入力）';
    final content = data['content'] ?? '（内容未入力）';
    final result = data['result'] ?? '（実績未入力）';
    
    String dateStr = '日付不明';
    if (data['createdAt'] != null) {
      final timestamp = data['createdAt'] as Timestamp;
      dateStr = DateFormat('yyyy/MM/dd').format(timestamp.toDate());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey[200]!)),
      child: ExpansionTile(
        leading: const Icon(Icons.assignment, color: Colors.teal, size: 22),
        title: Padding(
          padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
          child: Text(
            dateStr, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            '目標: $target', 
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('【活動内容】', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(content, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 14),
                  const Text('【本日の実績結果】', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(result, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}