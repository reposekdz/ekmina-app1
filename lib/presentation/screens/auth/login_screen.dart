import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../routes/app_router.dart';
import 'register_screen.dart';
import 'password_reset_screen.dart';
import '../../../core/localization/app_localizations_new.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String language;
  
  const LoginScreen({super.key, this.language = 'rw'});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = SecureStorageService();
  final _biometric = BiometricService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometric.canCheckBiometrics();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await _biometric.authenticateForLogin();
    if (authenticated) {
      final phone = await _storage.getUserPhone();
      if (phone != null) {
        // In a real app, you'd handle token refresh or re-auth here
        _handleLogin(); 
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final api = ref.read(apiClientProvider);
        final response = await api.login(_phoneController.text, _passwordController.text);
        
        if (response['token'] != null) {
          await _storage.saveAuthToken(response['token']);
          await _storage.saveUserId(response['user']['id']);
          await _storage.saveUserPhone(response['user']['phone']);
          
          if (mounted) context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorHandler.handleError(e)), 
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations(widget.language);
    
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 48),
                      _buildHeader(localizations),
                      const SizedBox(height: 32),
                      _buildInputField(
                        controller: _phoneController,
                        label: 'Nimero ya Telefoni',
                        hint: '078XXXXXXX',
                        icon: LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      _buildInputField(
                        controller: _passwordController,
                        label: 'Ijambo ry\'ibanga',
                        hint: '••••••••',
                        icon: LucideIcons.lock,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                        validator: Validators.validatePassword,
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 12),
                      _buildForgotPassword(localizations),
                      const SizedBox(height: 40),
                      _buildLoginButton(localizations).animate().fadeIn(delay: 600.ms).scale(),
                      const SizedBox(height: 32),
                      _buildRegisterLink(localizations).animate().fadeIn(delay: 800.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Opacity(
          opacity: 0.03,
          child: Column(
            children: List.generate(10, (index) => Expanded(
              child: Row(
                children: List.generate(5, (idx) => const Expanded(
                  child: Icon(LucideIcons.landmark, size: 100),
                )),
              ),
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(LucideIcons.landmark, color: Colors.white, size: 40),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Muraho!',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
        ),
        const SizedBox(height: 8),
        Text(
          'Injira kugira ngo ukomeze gukoresha E-Kimina.',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(obscureText ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
                  onPressed: onTogglePassword,
                )
              : null,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildForgotPassword(AppLocalizations localizations) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PasswordResetScreen())),
        child: const Text(
          'Wibagiwe ijambo ry\'ibanga?',
          style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AppLocalizations localizations) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              gradient: !_isLoading ? AppTheme.primaryGradient : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: !_isLoading ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ] : null,
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) 
                : const Text('Injira', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        if (_biometricAvailable) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _handleBiometricLogin,
            icon: const Icon(LucideIcons.fingerprint),
            label: const Text('Injira n\'intoki'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.2)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterLink(AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Nturaba umunyamuryango?', style: TextStyle(color: Colors.grey.shade600)),
        TextButton(
          onPressed: () => context.go('/register'), 
          child: const Text('Iyandikishe hano', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
