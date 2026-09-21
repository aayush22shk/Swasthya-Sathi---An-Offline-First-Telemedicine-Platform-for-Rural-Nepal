import 'package:flutter/material.dart';
import 'src/features/auth/view/welcome_view.dart';
import 'src/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore JWT session from disk — silent no-op if no previous session.
  await AuthService().loadSavedSession();

  runApp(const SwasthyaSathiApp());
}

class SwasthyaSathiApp extends StatelessWidget {
  const SwasthyaSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swasthya Sathi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0072FF)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        fontFamily: 'Roboto',
      ),
      home: const WelcomeView(),
    );
  }
}

