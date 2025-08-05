import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/participant.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../utils/settlement_calculator.dart';

class ExpensesScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const ExpensesScreen({super.key, this.onDataChanged});

  @override
  State<ExpensesScreen> createState() => ExpensesScreenState();
}

class ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  List<Participant> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        StorageService.loadExpenses(),
        StorageService.loadParticipants(),
      ]);
      _expenses = results[0] as List<Expense>;
      _participants = results[1] as List<Participant>;
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

  Future<void> _saveExpenses() async {
    try {
      await StorageService.saveExpenses(_expenses);
      widget.onDataChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  void _addExpense() {
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に参加者を追加してください')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ExpenseDialog(
        participants: _participants,
        onSave: (expense) {
          setState(() {
            _expenses.add(expense);
          });
          _saveExpenses();
        },
      ),
    );
  }

  void _editExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => _ExpenseDialog(
        participants: _participants,
        expense: expense,
        onSave: (updatedExpense) {
          setState(() {
            final index = _expenses.indexWhere((e) => e.id == expense.id);
            if (index != -1) {
              _expenses[index] = updatedExpense;
            }
          });
          _saveExpenses();
        },
      ),
    );
  }

  void _deleteExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支出を削除'),
        content: Text('${expense.item}を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _expenses.removeWhere((e) => e.id == expense.id);
              });
              _saveExpenses();
              Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  String _getSplitTargetText(Expense expense) {
    if (expense.includeIds.isNotEmpty) {
      return '対象指定: ${expense.includeIds.length}人で分割';
    } else if (expense.excludeIds.isNotEmpty) {
      final remaining = _participants.length - expense.excludeIds.length;
      return '除外指定: $remaining人で分割（${expense.excludeIds.length}人除外）';
    } else {
      return '全員: ${_participants.length}人で分割';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // Expenses list
          Expanded(
            child: _expenses.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '支出が登録されていません',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '右下の + ボタンから追加してください',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final expense = _expenses[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // タイトル行
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      expense.item,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '¥${NumberFormat('#,###').format(expense.amount.toInt())}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 支払い者情報
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '支払い: ${expense.payerId}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // 分割対象情報
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.group,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _getSplitTargetText(expense),
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),

                              // 除外・包含の詳細表示（チップ形式）
                              if (expense.excludeIds.isNotEmpty ||
                                  expense.includeIds.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (expense.excludeIds.isNotEmpty)
                                      ...expense.excludeIds.map((name) => Chip(
                                            label: Text('除外: $name'),
                                            backgroundColor: Colors.red[50],
                                            labelStyle: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: 12,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          )),
                                    if (expense.includeIds.isNotEmpty)
                                      ...expense.includeIds.map((name) => Chip(
                                            label: Text('対象: $name'),
                                            backgroundColor: Colors.blue[50],
                                            labelStyle: TextStyle(
                                              color: Colors.blue[700],
                                              fontSize: 12,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          )),
                                  ],
                                ),
                              ],

                              // アクションボタン
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _editExpense(expense),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('編集'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _deleteExpense(expense),
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text('削除'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _participants.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _addExpense,
              tooltip: '支出を追加',
              child: const Icon(Icons.add),
            ),
    );
  }
}

class _ExpenseDialog extends StatefulWidget {
  final List<Participant> participants;
  final Expense? expense;
  final Function(Expense) onSave;

  const _ExpenseDialog({
    required this.participants,
    this.expense,
    required this.onSave,
  });

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  late TextEditingController _itemController;
  late TextEditingController _amountController;
  String? _selectedPayerId;
  final Set<String> _excludeIds = {};
  final Set<String> _includeIds = {};

  // 分割方法: 'all' = 全員, 'exclude' = 除外指定, 'include' = 対象指定
  String _splitMethod = 'all';

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController(text: widget.expense?.item ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _selectedPayerId =
        widget.expense?.payerId ?? widget.participants.first.name;
    _excludeIds.addAll(widget.expense?.excludeIds ?? []);
    _includeIds.addAll(widget.expense?.includeIds ?? []);

    // 初期の分割方法を決定
    if (_includeIds.isNotEmpty) {
      _splitMethod = 'include';
    } else if (_excludeIds.isNotEmpty) {
      _splitMethod = 'exclude';
    } else {
      _splitMethod = 'all';
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool _isValid() {
    if (_itemController.text.trim().isEmpty) return false;
    if (_amountController.text.trim().isEmpty) return false;
    if (_selectedPayerId == null) return false;

    if (_splitMethod == 'include' && _includeIds.isEmpty) {
      return false;
    }

    if (_splitMethod == 'exclude' &&
        _excludeIds.length >= widget.participants.length) {
      return false;
    }

    final amount = double.tryParse(_amountController.text.trim());
    return amount != null && amount > 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.expense == null ? '支出を追加' : '支出を編集'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 項目名
              TextField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: '項目名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 金額
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: '金額',
                  border: OutlineInputBorder(),
                  prefixText: '¥',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // 支払い者
              DropdownButtonFormField<String>(
                value: _selectedPayerId,
                decoration: const InputDecoration(
                  labelText: '支払い者',
                  border: OutlineInputBorder(),
                ),
                items: widget.participants
                    .map((p) => DropdownMenuItem(
                          value: p.name,
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPayerId = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // 分割方法セクション
              Text(
                '分割対象',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // 分割方法選択
              DropdownButtonFormField<String>(
                value: _splitMethod,
                decoration: const InputDecoration(
                  labelText: '分割方法',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('全員で分割（${widget.participants.length}人）'),
                  ),
                  const DropdownMenuItem(
                    value: 'exclude',
                    child: Text('除外指定'),
                  ),
                  const DropdownMenuItem(
                    value: 'include',
                    child: Text('対象指定'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _splitMethod = value!;
                    _excludeIds.clear();
                    _includeIds.clear();
                  });
                },
              ),

              // 参加者選択（除外指定の場合）
              if (_splitMethod == 'exclude') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '除外する人を選択',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...widget.participants.map((participant) {
                        return CheckboxListTile(
                          title: Text(participant.name),
                          value: _excludeIds.contains(participant.name),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _excludeIds.add(participant.name);
                              } else {
                                _excludeIds.remove(participant.name);
                              }
                            });
                          },
                          dense: true,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],

              // 参加者選択（対象指定の場合）
              if (_splitMethod == 'include') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '分割対象の人を選択',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...widget.participants.map((participant) {
                        return CheckboxListTile(
                          title: Text(participant.name),
                          value: _includeIds.contains(participant.name),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _includeIds.add(participant.name);
                              } else {
                                _includeIds.remove(participant.name);
                              }
                            });
                          },
                          dense: true,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isValid()
              ? () {
                  final item = _itemController.text.trim();
                  final amountText = _amountController.text.trim();
                  final amount = double.parse(amountText);

                  // 分割方法に応じて除外・包含リストを設定
                  List<String> finalExcludeIds = [];
                  List<String> finalIncludeIds = [];

                  if (_splitMethod == 'exclude') {
                    finalExcludeIds = _excludeIds.toList();
                  } else if (_splitMethod == 'include') {
                    finalIncludeIds = _includeIds.toList();
                  }
                  // 'all'の場合は両方とも空リスト

                  final expense = Expense(
                    id: widget.expense?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    amount: amount,
                    item: item,
                    payerId: _selectedPayerId!,
                    excludeIds: finalExcludeIds,
                    includeIds: finalIncludeIds,
                  );

                  widget.onSave(expense);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
