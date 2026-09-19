import 'package:aullet/viewmodel/auth_view_model.dart';
import 'package:aullet/viewmodel/category_view_model.dart';
import 'package:aullet/viewmodel/profile_view_model.dart';
import 'package:aullet/views/auth/login_page.dart';
import 'package:aullet/views/auth/sign_up_page.dart';
import 'package:aullet/views/home_view.dart';
import 'package:aullet/views/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //caricamento file .env
  await dotenv.load(fileName: "assets/.env");

  //variabili per url del db e chiave
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  //Se una chiave non è definita, lancia un'eccezione descrittiva
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      "Errore nel file .env: manca SUPABASE_URL o SUPABASE_ANON_KEY",
    );
  }

  //uso publishableKey al posto di anonKey perché quest ultima è deprecated
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel())
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, _) {
          return MaterialApp(
            title: 'Aullet',
            theme: ThemeData(useMaterial3: true),
            debugShowCheckedModeBanner: false,
            home: authVM.isLoggedIn ? const HomeView() : const LoginPage(),
            routes: {
              '/login': (_) => const LoginPage(),
              '/signup': (_) => const SignUpPage(),
              '/home': (_) => const HomeView(),
              '/profile': (_) => const ProfilePage(),
            },
          );
        },
      ),
    );
  }
}
