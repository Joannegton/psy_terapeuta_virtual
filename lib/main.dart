import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PsyApp());
}

class PsyApp extends StatelessWidget {
  const PsyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Psy - Seu Terapeuta Virtual',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B73FF),
            brightness: Brightness.light,
          ).copyWith(
            primary: const Color(0xFF6B73FF),
            secondary: const Color(0xFF9C27B0),
            surface: const Color(0xFFF8F9FF),
            background: const Color(0xFFF8F9FF),
          ),
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF2D3748),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    final theme = Theme.of(this);
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? theme.colorScheme.error
            : theme.snackBarTheme.backgroundColor ??
                theme.colorScheme.inverseSurface,
      ),
    );
  }
}
