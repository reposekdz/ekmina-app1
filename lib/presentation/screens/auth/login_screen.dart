import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_handler.dart';
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
          
          ref.read(authStateProvider.notifier).state = true;
          
          if (mounted) context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00A86B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(localizations),
                const SizedBox(height: 40),
                _buildPhoneField(localizations),
                const SizedBox(height: 20),
                _buildPasswordField(localizations),
                const SizedBox(height: 12),
                _buildForgotPassword(localizations),
                const SizedBox(height: 32),
                _buildLoginButton(localizations),
                const SizedBox(height: 24),
                _buildRegisterLink(localizations),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.welcome, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00A86B))),
        const SizedBox(height: 8),
        Text(widget.language == 'rw' ? 'Injira kuri konti yawe' : widget.language == 'fr' ? 'Connectez-vous à votre compte' : 'Sign in to your account', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPhoneField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.phone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '078XXXXXXX',
            prefixIcon: const Icon(Icons.phone, color: Color(0xFF00A86B)),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A86B), width: 2)),
          ),
          validator: Validators.validatePhone,
        ),
      ],
    );
  }

  Widget _buildPasswordField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.password, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock, color: Color(0xFF00A86B)),
            suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A86B), width: 2)),
          ),
          validator: Validators.validatePassword,
        ),
      ],
    );
  }

  Widget _buildForgotPassword(AppLocalizations localizations) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PasswordResetScreen())),
        child: Text(localizations.forgotPassword, style: const TextStyle(color: Color(0xFF00A86B), fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLoginButton(AppLocalizations localizations) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B), foregroundColor: Colors.white, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text(localizations.login, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        if (_biometricAvailable) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _handleBiometricLogin,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Injira ukoresheje biometric'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56), side: const BorderSide(color: Color(0xFF00A86B))),
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterLink(AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(localizations.dontHaveAccount, style: TextStyle(color: Colors.grey[600])),
        TextButton(onPressed: () => context.go('/register'), child: Text(localizations.register, style: const TextStyle(color: Color(0xFF00A86B), fontWeight: FontWeight.bold))),
      ],
    );
  }
}
