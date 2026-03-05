import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/rwanda_location.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations_new.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String language;
  
  const RegisterScreen({super.key, this.language = 'rw'});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSector;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await RwandaLocation.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProvince == null || _selectedDistrict == null || _selectedSector == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uzuza aho utuye bihagije'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final api = ref.read(apiClientProvider);
        await api.register({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
          'province': _selectedProvince,
          'district': _selectedDistrict,
          'sector': _selectedSector,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konti yawe yafunguwe neza!'), backgroundColor: Colors.green),
          );
          context.go('/login');
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
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildInputField(
                            controller: _nameController,
                            label: 'Amazina yawe yose',
                            hint: 'Urugero: Keza Alice',
                            icon: LucideIcons.user,
                            validator: (v) => v?.isEmpty ?? true ? 'Injiza amazina yawe' : null,
                          ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: _phoneController,
                            label: 'Nimero ya Telefoni',
                            hint: '078XXXXXXX',
                            icon: LucideIcons.phone,
                            keyboardType: TextInputType.phone,
                            validator: Validators.validatePhone,
                          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
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
                          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: _confirmPasswordController,
                            label: 'Subiramo ijambo ry\'ibanga',
                            hint: '••••••••',
                            icon: LucideIcons.shieldCheck,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onTogglePassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            validator: (v) => v != _passwordController.text ? 'Amagambo ntabwo ahuje' : null,
                          ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                          const SizedBox(height: 32),
                          _buildLocationSection().animate().fadeIn(delay: 500.ms),
                          const SizedBox(height: 48),
                          _buildRegisterButton().animate().fadeIn(delay: 600.ms).scale(curve: Curves.easeOutBack),
                          const SizedBox(height: 32),
                          _buildLoginLink().animate().fadeIn(delay: 700.ms),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                  child: Icon(LucideIcons.userPlus, size: 100),
                )),
              ),
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Iyandikishe',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1.5),
        ),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Fungura konti yawe utangire kuzigama mu buryo bugezweho.',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
            ),
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(obscureText ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: Colors.grey),
                  onPressed: onTogglePassword,
                )
              : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              const Text('Aho utuye', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _buildDropdown('Intara', _selectedProvince, RwandaLocation.getProvinces(), (v) {
            setState(() {
              _selectedProvince = v;
              _selectedDistrict = _selectedSector = null;
            });
          }),
          if (_selectedProvince != null) ...[
            const SizedBox(height: 12),
            _buildDropdown('Akarere', _selectedDistrict, RwandaLocation.getDistricts(_selectedProvince!), (v) {
              setState(() {
                _selectedDistrict = v;
                _selectedSector = null;
              });
            }),
          ],
          if (_selectedDistrict != null) ...[
            const SizedBox(height: 12),
            _buildDropdown('Umurenge', _selectedSector, RwandaLocation.getSectors(_selectedProvince!, _selectedDistrict!), (v) {
              setState(() => _selectedSector = v);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(LucideIcons.chevronDown, size: 18),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: Container(
        decoration: BoxDecoration(
          gradient: !_isLoading ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: !_isLoading ? [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ] : null,
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: _isLoading 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Fungura Konti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 20),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Ufite konti?', style: TextStyle(color: Colors.grey.shade600)),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Injira hano', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
