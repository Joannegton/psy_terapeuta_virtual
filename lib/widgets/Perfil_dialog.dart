
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:psy_therapist/main.dart';
import 'package:psy_therapist/providers/auth_provider.dart';

/// Um widget com estado para o conteúdo do dialog de perfil,
/// permitindo a edição do nome.
class ProfileDialog extends StatefulWidget {
  final AuthProvider authProvider;

  const ProfileDialog({required this.authProvider});

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
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateName() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.updateUserName(_nameController.text);
      if (mounted) {
        setState(() {
          _isEditing = false;
          _nameController.text = authProvider.user?.displayName ?? _nameController.text;
        });
        Navigator.of(context).pop();
        context.showSnackBar('Nome atualizado com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(authProvider.error ?? 'Erro ao atualizar o nome.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final creationDate = user?.metadata.creationTime;

        if (!_isEditing) {
          final currentName = authProvider.user?.displayName ?? '';
          if (_nameController.text != currentName) {
            _nameController.text = currentName;
          }
        }

        String memberSince = 'Data não disponível';
        if (creationDate != null) {
          memberSince = '${authProvider.userModel?.createdAt.day}/${authProvider.userModel?.createdAt.month}/${authProvider.userModel?.createdAt.year}';
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
                        onPressed: () => setState(() => _isEditing = true),
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
