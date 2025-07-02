import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'welcome_screen.dart';
import 'chat_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
          // Inicializar chat para o usuário
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ChatProvider>().initializeChat(authProvider.user!.uid);
          });
          
          return const ChatScreen();
        }

        // Se usuário não está autenticado, mostrar tela de boas-vindas
        return const WelcomeScreen();
      },
    );
  }
}
