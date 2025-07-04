
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:psy_therapist/main.dart';
import 'package:psy_therapist/providers/auth_provider.dart';

/// Um widget com estado para o conteúdo do dialog de perfil,
/// permitindo a edição do nome.
class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController = TextEditingController(text: authProvider.user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateName() async {
    if (!_formKey.currentState!.validate()) return;

    // Pega o Navigator antes da chamada assíncrona para evitar usar o context
    // de um widget que não está mais na árvore.
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final theme = Theme.of(context);

    try {
      await authProvider.updateUserName(_nameController.text);
      if (!mounted) return;
      // Fecha o dialog primeiro
      Navigator.of(context).pop();
      // Depois mostra a notificação
      messenger.showSnackBar(const SnackBar(content: Text('Nome atualizado com sucesso!')));
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
            content: Text(authProvider.error ?? 'Erro ao atualizar o nome.'),
            backgroundColor: theme.colorScheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final creationDate = authProvider.userModel?.createdAt;

        String memberSince = 'Data não disponível';
        if (creationDate != null) {
          // Usar o pacote intl para formatação de data localizada e robusta.
          memberSince = DateFormat.yMd('pt_BR').format(creationDate);
        }

        return AlertDialog(
          title: const Text('Perfil'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nome:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_isEditing)
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Digite seu nome'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'O nome não pode ser vazio.';
                      }
                      return null;
                    },
                  )
                else
                  Row(
                    children: [
                      Expanded(child: Text(authProvider.user?.displayName ?? 'Não informado')),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () {
                          // Garante que o controller tem o texto mais recente antes de editar
                          _nameController.text = authProvider.user?.displayName ?? '';
                          setState(() => _isEditing = true);
                        },
                        tooltip: 'Editar nome',
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(user?.email ?? 'Email não disponível'),
                const SizedBox(height: 16),
                const Text('Membro desde:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(memberSince),
              ],
            ),
          ),
          actions: _isEditing
              ? _buildEditingActions(context, authProvider.isProfileLoading)
              : [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
        );
      },
    );
  }

  List<Widget> _buildEditingActions(BuildContext context, bool isLoading) {
    return [
      TextButton(
        onPressed: isLoading ? null : () => setState(() => _isEditing = false),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: isLoading ? null : _handleUpdateName,
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Salvar'),
      ),
    ];
  }
}
