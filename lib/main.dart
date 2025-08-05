import 'package:flutter/material.dart';
import 'screens/participants_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/settlement_screen.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const WarikanApp());
}

class WarikanApp extends StatelessWidget {
  const WarikanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '旅ワリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF15283A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ParticipantsScreenState> _participantsKey = GlobalKey();
  final GlobalKey<ExpensesScreenState> _expensesKey = GlobalKey();
  final GlobalKey<SettlementScreenState> _settlementKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    _participantsKey.currentState?.loadData();
    _expensesKey.currentState?.loadData();
    _settlementKey.currentState?.refreshSettlement();
  }

  void _resetAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全データをリセット'),
        content:
            const Text('参加者と支出のすべてのデータが削除されます。\nこの操作は取り消せません。\n\n本当に削除しますか？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // データを削除
              await StorageService.clearAll();

              // 全画面を更新
              _refreshData();

              // 完了メッセージを表示
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('すべてのデータを削除しました'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '旅ワリ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF15283A),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: '参加者',
            ),
            Tab(
              icon: Icon(Icons.receipt_long),
              text: '支出',
            ),
            Tab(
              icon: Icon(Icons.calculate),
              text: '精算',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _resetAllData,
            tooltip: '全データをリセット',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ParticipantsScreen(
            key: _participantsKey,
            onDataChanged: _refreshData,
          ),
          ExpensesScreen(
            key: _expensesKey,
            onDataChanged: _refreshData,
          ),
          SettlementScreen(
            key: _settlementKey,
          ),
        ],
      ),
    );
  }
}
