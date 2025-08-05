import '../models/participant.dart';
import '../models/expense.dart';
import '../models/settlement.dart';

class SettlementCalculator {
  /// 精算計算を実行
  static Settlement calculate(
    List<Participant> participants,
    List<Expense> expenses,
  ) {
    // 各参加者の精算額を計算
    final balances = _calculateBalances(participants, expenses);

    // 最適化された送金リストを生成
    final payments = _generateOptimalPayments(balances);

    return Settlement(balances: balances, payments: payments);
  }

  /// 各参加者の精算額を計算（+受け取り/-支払い）
  static Map<String, double> _calculateBalances(
    List<Participant> participants,
    List<Expense> expenses,
  ) {
    final balances = <String, double>{};

    // 初期化
    for (final participant in participants) {
      balances[participant.name] = 0.0;
    }

    for (final expense in expenses) {
      // 対象参加者を決定
      Set<String> targetParticipants = participants.map((p) => p.name).toSet();

      // includeIds が指定されている場合、その人たちのみが対象
      if (expense.includeIds.isNotEmpty) {
        targetParticipants = expense.includeIds.toSet();
      }

      // excludeIds の人たちを除外
      for (final excludeId in expense.excludeIds) {
        targetParticipants.remove(excludeId);
      }

      if (targetParticipants.isEmpty) continue;

      // 一人当たりの負担額
      final amountPerPerson = expense.amount / targetParticipants.length;

      // 支払い者は支出分をプラス
      balances[expense.payerId] =
          (balances[expense.payerId] ?? 0) + expense.amount;

      // 対象者全員が負担額分をマイナス
      for (final participantName in targetParticipants) {
        balances[participantName] =
            (balances[participantName] ?? 0) - amountPerPerson;
      }
    }

    return balances;
  }

  /// 最適化された送金リストを生成（貪欲アルゴリズム）
  static List<Payment> _generateOptimalPayments(Map<String, double> balances) {
    final payments = <Payment>[];

    // 精算額をコピー（元のデータを変更しないため）
    final remainingBalances = Map<String, double>.from(balances);

    while (true) {
      // 最も多く受け取るべき人
      String? maxCreditor;
      double maxCredit = 0;

      // 最も多く支払うべき人
      String? maxDebtor;
      double maxDebt = 0;

      for (final entry in remainingBalances.entries) {
        if (entry.value > maxCredit) {
          maxCredit = entry.value;
          maxCreditor = entry.key;
        }
        if (entry.value < -maxDebt) {
          maxDebt = -entry.value;
          maxDebtor = entry.key;
        }
      }

      // 精算完了判定（すべての残高が実質0）
      if (maxCredit < 1 && maxDebt < 1) break;

      if (maxCreditor != null && maxDebtor != null) {
        // 送金額は小さい方の絶対値
        final paymentAmount = maxCredit < maxDebt ? maxCredit : maxDebt;

        if (paymentAmount >= 1) {
          // 1円未満は無視
          payments.add(Payment(
            fromId: maxDebtor,
            toId: maxCreditor,
            amount: paymentAmount,
          ));

          // 残高を更新
          remainingBalances[maxCreditor] =
              remainingBalances[maxCreditor]! - paymentAmount;
          remainingBalances[maxDebtor] =
              remainingBalances[maxDebtor]! + paymentAmount;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return payments;
  }


}
