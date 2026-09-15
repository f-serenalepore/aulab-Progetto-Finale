import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  //Registra utente via email e password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signUp(password: password, email: email);
  }

  //Esegue login via email e password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(password: password, email: email);
  }

  //Esegue logout
  Future<void> signOut() {
    return _supabase.auth.signOut();
  }

  //Restituisce l'utente attualmente loggato, oppure null
  User? get currentUser => _supabase.auth.currentUser;
}
