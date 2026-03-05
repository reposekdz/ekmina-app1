import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations_new.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _currentLanguage = 'rw';

  void _changeLanguage(String lang) {
    setState(() => _currentLanguage = lang);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations(_currentLanguage);
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          
          // Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildLanguageSelector(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeroSection(localizations),
                        const SizedBox(height: 60),
                        _buildActionButtons(localizations),
                        const SizedBox(height: 60),
                        _buildFeatureRow(localizations),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _langChip('RW', 'rw'),
          const SizedBox(width: 8),
          _langChip('EN', 'en'),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: -0.2);
  }

  Widget _langChip(String label, String code) {
    final isSelected = _currentLanguage == code;
    return GestureDetector(
      onTap: () => _changeLanguage(code),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryBlue : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(AppLocalizations localizations) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
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
            size: 64,
            color: AppTheme.primaryBlue,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 32),
        const Text(
          'E-Kimina',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(height: 8),
        Text(
          _currentLanguage == 'rw' 
            ? 'Kuzigama no Kugurizanya mu buryo bugezweho'
            : 'Modern Digital Savings & Loans',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w300,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen(language: _currentLanguage)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: const Text(
              'Tangira None',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegisterScreen(language: _currentLanguage)),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text(
              'Iyandikishe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildFeatureRow(AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _featureIcon(LucideIcons.shieldCheck, 'Umutekano'),
        _featureIcon(LucideIcons.zap, 'Byihuse'),
        _featureIcon(LucideIcons.checkCircle, 'Byizewe'),
      ],
    ).animate().fadeIn(delay: 1000.ms);
  }

  Widget _featureIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        '© 2024 E-Kimina Rwanda. Made with ❤️ in Kigali',
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
      ),
    ).animate().fadeIn(delay: 1200.ms);
  }
}
