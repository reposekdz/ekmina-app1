import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../routes/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _statusMessage = 'Tegereza...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 2000)); // Minimum splash time

      final storage = SecureStorageService();
      final token = await storage.getAuthToken();
      final userId = await storage.getUserId();

      if (token != null && userId != null) {
        setState(() => _statusMessage = 'Kureba konti...');
        try {
          final api = ref.read(apiClientProvider);
          await api.getWallet(userId);
          
          ref.read(authStateProvider.notifier).state = true;
          if (mounted) context.go('/home');
        } catch (e) {
          await storage.clearAll();
          if (mounted) context.go('/welcome');
        }
      } else {
        if (mounted) context.go('/welcome');
      }
    } catch (e) {
      if (mounted) context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.landmark,
                size: 60,
                color: AppTheme.primaryBlue,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).shimmer(delay: 800.ms),
            const SizedBox(height: 32),
            const Text(
              'E-Kimina',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const Text(
              'RWANDA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 4,
              ),
            ).animate().fadeIn(delay: 400.ms),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
