import 'package:aullet/models/expense.dart';
import 'package:aullet/repositories/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseViewModel extends ChangeNotifier {
  final _expenseRepo = ExpenseRepository();

  List<Expense> _expense = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expense => _expense;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  //carica le spese dal repository
  Future<void> loadExpenses() async {
    _setLoading(true);

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        _error = 'Utente non autenticato';
        return;
      }
      _expense = await _expenseRepo.fetchExpenses(user.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    if (v) _error = null;
    notifyListeners();
  }
}
