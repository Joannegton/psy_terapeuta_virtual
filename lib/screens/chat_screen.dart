import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:psy_therapist/widgets/Perfil_dialog.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Theme.of(context).brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/images/psy_png.png',
                fit: BoxFit.contain,
              )
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Psy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Terapeuta Virtual',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'new_conversation') {
                        _showNewConversationDialog(context, chatProvider);
                      } else if (value == 'clear_chat') {
                        _showClearChatDialog(context, chatProvider);
                      } else if (value == 'profile') {
                        _showProfileDialog(context, authProvider);
                      } else if (value == 'logout') {
                        _showLogoutDialog(context, authProvider);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline),
                            SizedBox(width: 12),
                            Text('Perfil'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'new_conversation',
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded),
                            SizedBox(width: 12),
                            Text('Nova Conversa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear_chat',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded),
                            SizedBox(width: 12),
                            Text('Limpar Chat'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded),
                            SizedBox(width: 12),
                            Text('Sair'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          if (chatProvider.messages.isNotEmpty) {
            _scrollToBottom();
          }

          return Column(
            children: [
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          return MessageBubble(
                            message: message,
                            isLast: index == chatProvider.messages.length - 1,
                          ).animate().fadeIn(
                            delay: Duration(milliseconds: index * 100),
                          ).slideX(begin: message.type.name == 'user' ? 0.3 : -0.3);
                        },
                      ),
              ),
              
              if (!chatProvider.isConversationEnded)
                ChatInput(
                  onSendMessage: chatProvider.sendMessage,
                  isLoading: chatProvider.isLoading,
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Conversa encerrada',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => chatProvider.startNewConversation(),
                        child: const Text('Iniciar Nova Conversa'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Conversa'),
        content: const Text('Deseja iniciar uma nova conversa? O histórico atual será perdido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              chatProvider.startNewConversation();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Chat'),
        content: const Text('Deseja limpar todo o histórico de conversas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              chatProvider.clearChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => ProfileDialog(authProvider: authProvider),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

}
