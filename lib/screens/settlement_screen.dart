import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/participant.dart';
import '../models/expense.dart';
import '../models/settlement.dart';
import '../services/storage_service.dart';
import '../utils/settlement_calculator.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => SettlementScreenState();
}

class SettlementScreenState extends State<SettlementScreen> {
  List<Participant> _participants = [];
  List<Expense> _expenses = [];
  Settlement? _settlement;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refreshSettlement();
  }

  Future<void> refreshSettlement() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        StorageService.loadParticipants(),
        StorageService.loadExpenses(),
      ]);
      _participants = results[0] as List<Participant>;
      _expenses = results[1] as List<Expense>;

      if (_participants.isNotEmpty && _expenses.isNotEmpty) {
        _settlement = SettlementCalculator.calculate(_participants, _expenses);
      } else {
        _settlement = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSummaryCard() {
    final totalExpenses =
        _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final averagePerPerson =
        _participants.isNotEmpty ? totalExpenses / _participants.length : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '概要',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('参加者数：'),
                Text('${_participants.length}人'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('支出項目数：'),
                Text('${_expenses.length}件'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('支出総額：'),
                Text(
                  '¥${NumberFormat('#,###').format(totalExpenses.toInt())}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('一人当たり平均：'),
                Text(
                  '¥${NumberFormat('#,###').format(averagePerPerson.toInt())}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalancesCard() {
    if (_settlement == null) return const SizedBox.shrink();

    final sortedBalances = _settlement!.balances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '各人の精算額',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '（＋受け取り / −支払い）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const Divider(),
            ...sortedBalances.map((entry) {
              final amount = entry.value;
              final isPositive = amount > 0;
              final isNeutral = amount.abs() < 1;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isNeutral
                            ? Colors.grey[100]
                            : isPositive
                                ? Colors.green[50]
                                : Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isNeutral
                              ? Colors.grey[300]!
                              : isPositive
                                  ? Colors.green[300]!
                                  : Colors.red[300]!,
                        ),
                      ),
                      child: Text(
                        isNeutral
                            ? '精算済み'
                            : '${isPositive ? '+' : ''}¥${NumberFormat('#,###').format(amount.abs().toInt())}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isNeutral
                              ? Colors.grey[600]
                              : isPositive
                                  ? Colors.green[700]
                                  : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsCard() {
    if (_settlement == null || _settlement!.payments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.swap_horiz,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '送金リスト',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
              const Divider(),
              const Icon(Icons.check_circle_outline,
                  size: 48, color: Colors.green),
              const SizedBox(height: 8),
              const Text(
                '精算完了！',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text('送金の必要はありません'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '最適送金リスト',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '（最小送金数: ${_settlement!.payments.length}回）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const Divider(),
            ..._settlement!.payments.asMap().entries.map((entry) {
              final index = entry.key;
              final payment = entry.value;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3F54),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4A5F74),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF15283A),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              payment.fromId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward,
                              color: Colors.white70),
                          Expanded(
                            child: Text(
                              payment.toId,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15283A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        '¥${NumberFormat('#,###').format(payment.amount.toInt())}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_participants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '参加者が登録されていません',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '参加者タブから参加者を追加してください',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_expenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '支出が登録されていません',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '支出タブから支出を追加してください',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildBalancesCard(),
          const SizedBox(height: 16),
          _buildPaymentsCard(),
        ],
      ),
    );
  }
}
