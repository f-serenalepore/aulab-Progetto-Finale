import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class StatisticsViewModel extends ChangeNotifier {
  final _repo = ExpenseRepository();
  List<Expense> _allExpenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get allExpenses => _allExpenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carica tutte le spese dell'utente
  Future<void> loadExpenses() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Utente non autenticato');
      _allExpenses = await _repo.fetchExpenses(user.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Calcola totale spese per mese per l'anno selezionato
  Map<int, double> calculateMonthlyExpenses(int year) {
    final Map<int, double> totals = {for (var m = 1; m <= 12; m++) m: 0.0};

    for (final exp in _allExpenses) {
      if (exp.date.year == year) {
        totals[exp.date.month] = totals[exp.date.month]! + exp.amount;
      }
    }

    return totals;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
