import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../routes/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _statusMessage = 'Tegereza...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _statusMessage = 'Gutangiza...');
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _statusMessage = 'Kureba umutekano...');
      final storage = SecureStorageService();
      final token = await storage.getAuthToken();
      final userId = await storage.getUserId();

      if (token != null && userId != null) {
        setState(() => _statusMessage = 'Kureba konti...');
        try {
          final api = ref.read(apiClientProvider);
          await api.getWallet(userId);
          
          setState(() => _statusMessage = 'Byagenze neza!');
          await Future.delayed(const Duration(milliseconds: 500));
          
          ref.read(authStateProvider.notifier).state = true;
          if (mounted) context.go('/home');
        } catch (e) {
          await storage.clearAuthData();
          setState(() => _statusMessage = 'Injira...');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) context.go('/login');
        }
      } else {
        setState(() => _statusMessage = 'Murakaza neza!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go('/login');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Ikosa ryabaye...');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.7), AppTheme.accentBlue.withOpacity(0.5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15)),
                                BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.5), blurRadius: 40, spreadRadius: 5),
                              ],
                            ),
                            child: const Icon(Icons.account_balance_wallet, size: 70, color: AppTheme.primaryGreen),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'E-Kimina',
                            style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Rwanda',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white70, letterSpacing: 4),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Digitizing Savings Groups',
                              style: TextStyle(fontSize: 14, color: Colors.white, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'v1.0.0',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
