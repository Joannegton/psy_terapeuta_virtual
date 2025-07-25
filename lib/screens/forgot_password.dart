import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:psy_therapist/main.dart';
import 'package:psy_therapist/widgets/custom_textfield.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.resetPassword(_emailController.text.trim());

    if (success) {
      setState(() {
        _emailSent = true;
      });
    } else if (mounted) {
      context.showSnackBar(
        authProvider.error ?? 'Erro ao enviar email',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Ícone
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _emailSent ? Icons.mark_email_read_outlined : Icons.lock_reset,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (!_emailSent) ...[
                    // Título e descrição
                    Text(
                      'Esqueceu sua senha?',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Digite seu email e enviaremos um link para redefinir sua senha.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                    
                    const SizedBox(height: 40),
                    
                    // Campo de email
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'Digite seu email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite seu email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Digite um email válido';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.3),
                    
                    const SizedBox(height: 32),
                    
                    // Botão enviar
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleResetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Enviar Link',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5),
                  ] else ...[
                    // Confirmação de email enviado
                    Text(
                      'Email Enviado!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Enviamos um link de recuperação para:\n${_emailController.text}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Verifique sua caixa de entrada e spam.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 600.ms),
                    
                    const SizedBox(height: 40),
                    
                    // Botão voltar
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Voltar ao Login',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
