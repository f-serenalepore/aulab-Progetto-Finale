import 'package:aullet/models/expense.dart';
import 'package:aullet/repositories/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseViewModel extends ChangeNotifier {
  final _expenseRepo = ExpenseRepository();

  List<Expense> _expense = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get expense => _expense;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool v) {
    _isLoading = v;
    if (v) _errorMessage = null;
    notifyListeners();
  }

  //carica le spese dal repository
  Future<void> loadExpenses() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Utente non autenticato');
      _expense = await _expenseRepo.fetchExpenses(user.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      _errorMessage = null;

      await _expenseRepo.updateExpense(expense);

      // Aggiorna anche la lista locale
      final index = _expense.indexWhere((e) => e.id == expense.id);

      if (index != -1) {
        _expense[index] = expense;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      _errorMessage = null;

      await _expenseRepo.deleteExpense(id);

      // Rimuove la spesa dalla lista locale
      _expense.removeWhere((expense) => expense.id == id);

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  //Metodo per aggiungere la spesa
  Future<void> addExpense(Expense exp) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Utente non autenticato');
      await _expenseRepo.insertExpense(exp);
      _expense = await _expenseRepo.fetchExpenses(user.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }
}
