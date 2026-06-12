import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 👈 追加
import 'firebase_options.dart'; // 👈 追加（flutterfire configureを実行すると自動生成されるファイルです）

// 作成した3つの画面ファイルをインポート
import 'target_screen.dart';
import 'today_activity_screen.dart';
import 'history_screen.dart';

void main() async {
  // 👈 async を追加
  WidgetsFlutterBinding.ensureInitialized(); // 👈 追加
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 👈 追加
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainBottomNavigation(),
    );
  }
}

// 下部ナビゲーションを管理する仕組み
class MainBottomNavigation extends StatefulWidget {
  const MainBottomNavigation({super.key});

  @override
  State<MainBottomNavigation> createState() => _MainBottomNavigationState();
}

class _MainBottomNavigationState extends State<MainBottomNavigation> {
  // 現在表示しているタブの番号（0からスタート）
  int _selectedIndex = 0;

  // 表示する画面のリスト（ここで3つの部屋を合体させています）
  final List<Widget> _screens = [
    const TargetScreen(),        // 0: 目標設定
    const TodayActivityScreen(), // 1: 今日の活動
    const HistoryScreen(),       // 2: 履歴参照
  ];

  // タブがタップされた時の処理
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 画面を更新する命令
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // 現在選ばれている画面を表示
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal, // 選ばれている時の色
        unselectedItemColor: Colors.grey, // 選ばれていない時の色
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: '目標設定'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: '今日の活動'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '活動参照'),
        ],
      ),
    );
  }
}