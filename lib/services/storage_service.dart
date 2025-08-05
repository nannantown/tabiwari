import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/participant.dart';
import '../models/expense.dart';

class StorageService {
  static const String _participantsKey = 'participants';
  static const String _expensesKey = 'expenses';

  /// 参加者リストを保存
  static Future<void> saveParticipants(List<Participant> participants) async {
    final prefs = await SharedPreferences.getInstance();
    final json = participants.map((p) => p.toJson()).toList();
    await prefs.setString(_participantsKey, jsonEncode(json));
  }

  /// 参加者リストを読み込み
  static Future<List<Participant>> loadParticipants() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_participantsKey);
    if (jsonString == null) return [];

    final List<dynamic> json = jsonDecode(jsonString);
    return json.map((p) => Participant.fromJson(p)).toList();
  }

  /// 支出リストを保存
  static Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final json = expenses.map((e) => e.toJson()).toList();
    await prefs.setString(_expensesKey, jsonEncode(json));
  }

  /// 支出リストを読み込み
  static Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_expensesKey);
    if (jsonString == null) return [];

    final List<dynamic> json = jsonDecode(jsonString);
    return json.map((e) => Expense.fromJson(e)).toList();
  }

  /// すべてのデータをクリア
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_participantsKey);
    await prefs.remove(_expensesKey);
  }
}
