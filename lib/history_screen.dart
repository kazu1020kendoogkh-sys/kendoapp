import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 Firestoreを読み込むために必要
import 'package:intl/intl.dart'; // 👈 日付を綺麗に表示するためのパッケージ（後ほど説明します）

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('活動参照部屋', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: '日単位で見る'), Tab(text: '週単位で見る')],
          ),
        ),
        body: const TabBarView(
          children: [
            HistoryList(unit: '日'),
            Center(child: Text('週単位の表示は今後実装します')), // 一旦シンプルに
          ],
        ),
      ),
    );
  }
}

class HistoryList extends StatelessWidget {
  final String unit;
  const HistoryList({super.key, required this.unit});

  @override
  Widget build(BuildContext context) {
    // 👈 StreamBuilderを使って、Firestoreの「activities」コレクションをリアルタイム監視します
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activities')
          .orderBy('createdAt', descending: true) // 新しい投稿順に並び替える
          .snapshots(),
      builder: (context, snapshot) {
        // 1. 接続エラーが起きた場合
        if (snapshot.hasError) {
          return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
        }

        // 2. データを読み込み中の場合（ぐるぐるを表示）
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
        }

        // 3. データが1件も入っていない場合
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('まだ活動記録がありません。\n今日の活動部屋から入力してみましょう！', textAlign: TextAlign.center));
        }

        // 4. 無事にデータが取得できた場合、リストを作成
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            // 1つのデータをマップ（辞書型）として取り出す
            final data = docs[index].data() as Map<String, dynamic>;

            // 各項目を取り出す（もし空っぽなら「なし」と表示）
            final target = data['target'] ?? '（目標未入力）';
            final content = data['content'] ?? '（内容未入力）';
            final result = data['result'] ?? '（実績未入力）';
            
            // 日付データの変換処理
            String dateStr = '';
            if (data['createdAt'] != null) {
              final timestamp = data['createdAt'] as Timestamp;
              final dateTime = timestamp.toDate();
              dateStr = DateFormat('yyyy/MM/dd HH:mm').format(dateTime); // 綺麗に見やすく整形
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: const Icon(Icons.calendar_today, color: Colors.teal),
                title: Text(target, maxLines: 1, overflow: TextOverflow.ellipsis), // 1行だけタイトルっぽく表示
                subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('【活動内容】', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          Text(content),
                          const SizedBox(height: 12),
                          const Text('【本日の実績結果】', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          Text(result),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}