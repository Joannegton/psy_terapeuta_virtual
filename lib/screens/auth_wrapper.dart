import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'welcome_screen.dart';
import 'chat_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChatInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Mostrar loading enquanto verifica autenticação
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Se usuário está autenticado
        if (authProvider.isAuthenticated) {
          // Initialize chat only once after login
          if (!_isChatInitialized) {
            _isChatInitialized = true;
            // Use a post-frame callback to ensure providers are available.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) { // Check if the widget is still in the tree
                context.read<ChatProvider>().initializeChat(authProvider.user!.uid);
              }
            });
          }
          return const ChatScreen();
        }

        // Se usuário não está autenticado, mostrar tela de boas-vindas
        _isChatInitialized = false; // Reset flag on logout
        return const WelcomeScreen();
      },
    );
  }
}
