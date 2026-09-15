import 'package:aullet/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  final _authService = AuthService();

  //vogliamo tenere il controllo dello stato dentro il ViewModel, quindi dichiariamo private le variabili di stato
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn =
      false; //parametro booleano per verificare lo stato dell'utente loggato

  //esponiamo le variabili di stato attraverso getter
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  //costruttore per effettuare il controllo dell'utente appena viene creato il ViewModel
  AuthViewModel() {
    checkCurrentUser();
  }

  //metodo che controlla se c'è già un utente loggato in Supabase
  void checkCurrentUser() {
    _isLoggedIn = _authService.currentUser != null;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signUp(email: email, password: password);
      //Successo, nessun errore, puoi navigare o notificare l'utente
      _isLoggedIn = true;
    } on AuthException catch (error) {
      //cattura messaggio di AuthException
      _errorMessage = error.message;
    } catch (e) {
      //cattura qualsiasi altro errore
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signIn(email: email, password: password);
      //Successo, utente loggato
      _isLoggedIn = true;
    } on AuthException catch (error) {
      //cattura messaggio di AuthException
      _errorMessage = error.message;
    } catch (e) {
      //cattura qualsiasi altro errore
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    // Se serve, resetta qui stato utente
    _isLoggedIn = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    //Reset errore quando ricomincia il loading
    if (value) _errorMessage = null;
    notifyListeners();
  }
}
