import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('pt_BR', null);


  // Inicializa o Mobile Ads
  await MobileAds.instance.initialize();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    // appleProvider: AppleProvider.appAttest,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.dark, 
  ));

  runApp(const PsyApp());
}

class PsyApp extends StatelessWidget {
  const PsyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<AuthService>()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, auth, previousChat) {
            // Quando o usuário muda (login/logout), limpa o histórico de chat anterior.
            previousChat?.clearChatForNewUser(auth.user?.uid);
            return previousChat ?? ChatProvider();
          },
        ),
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
