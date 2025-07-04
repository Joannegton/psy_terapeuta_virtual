import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  InterstitialAd? _interstitialAd;
  bool _adShown = false;

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadInterstitialAd(VoidCallback onAdClosed) {
    print('Tentando carregar anúncio intersticial...');
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-7575556543606646/7402574144',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Anúncio intersticial carregado! Exibindo...');
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Anúncio fechado pelo usuário.');
              ad.dispose();
              _interstitialAd = null;
              onAdClosed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Falha ao exibir anúncio: \$error');
              ad.dispose();
              _interstitialAd = null;
              onAdClosed();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          print('Falha ao carregar anúncio: \$error');
          _interstitialAd = null;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Não foi possível exibir o anúncio.')),
            );
          }
          onAdClosed();
        },
      ),
    );
  }

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
          if (!_isChatInitialized && !_adShown) {
            _isChatInitialized = true;
            _adShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadInterstitialAd(() {
                if (mounted) {
                  context.read<ChatProvider>().initializeChat(authProvider.user!.uid);
                  setState(() {}); // Força rebuild para mostrar ChatScreen
                }
              });
            });
            // Enquanto o anúncio não fecha, mostra loading
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Após anúncio, mostra ChatScreen
          return const ChatScreen();
        }

        // Se usuário não está autenticado, mostrar tela de boas-vindas
        _isChatInitialized = false; // Reset flag on logout
        _adShown = false;
        return const WelcomeScreen();
      },
    );
  }
}
