import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/rwanda_location.dart';
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
  String? _selectedCell;
  String? _selectedVillage;

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
          SnackBar(content: Text(widget.language == 'rw' ? 'Uzuza aho utuye' : 'Please select your location'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final api = ref.read(apiClientProvider);
        final response = await api.register({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
          'province': _selectedProvince,
          'district': _selectedDistrict,
          'sector': _selectedSector,
          'cell': _selectedCell,
          'village': _selectedVillage,
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
    final localizations = AppLocalizations(widget.language);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00A86B)),
          onPressed: () => context.pop(),
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
                const SizedBox(height: 32),
                _buildNameField(localizations),
                const SizedBox(height: 20),
                _buildPhoneField(localizations),
                const SizedBox(height: 20),
                _buildPasswordField(localizations),
                const SizedBox(height: 20),
                _buildConfirmPasswordField(localizations),
                const SizedBox(height: 32),
                _buildLocationSection(localizations),
                const SizedBox(height: 40),
                _buildRegisterButton(localizations),
                const SizedBox(height: 24),
                _buildLoginLink(localizations),
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
        Text(localizations.register, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00A86B))),
        const SizedBox(height: 8),
        Text(widget.language == 'rw' ? 'Fungura konti nshya' : 'Create a new account', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildNameField(AppLocalizations localizations) {
    return _buildTextField(
      controller: _nameController,
      label: localizations.name,
      hint: localizations.enterName,
      icon: Icons.person,
      validator: (v) => v?.isEmpty ?? true ? localizations.enterName : null,
    );
  }

  Widget _buildPhoneField(AppLocalizations localizations) {
    return _buildTextField(
      controller: _phoneController,
      label: localizations.phone,
      hint: '078XXXXXXX',
      icon: Icons.phone,
      keyboardType: TextInputType.phone,
      formatters: [FilteringTextInputFormatter.digitsOnly],
      validator: Validators.validatePhone,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF00A86B)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A86B), width: 2)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField(AppLocalizations localizations) {
    return _buildTextField(
      controller: _passwordController,
      label: localizations.password,
      hint: '••••••••',
      icon: Icons.lock,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: Validators.validatePassword,
    );
  }

  Widget _buildConfirmPasswordField(AppLocalizations localizations) {
    return _buildTextField(
      controller: _confirmPasswordController,
      label: localizations.confirmPassword,
      hint: '••••••••',
      icon: Icons.lock,
      obscureText: _obscureConfirmPassword,
      suffixIcon: IconButton(
        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
      ),
      validator: (v) => v != _passwordController.text ? 'Amagambo ntabwo ahuje' : null,
    );
  }

  Widget _buildLocationSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.location, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00A86B))),
        const SizedBox(height: 16),
        _buildDropdown(localizations.selectProvince, _selectedProvince, RwandaLocation.getProvinces(), (v) {
          setState(() {
            _selectedProvince = v;
            _selectedDistrict = _selectedSector = _selectedCell = _selectedVillage = null;
          });
        }),
        if (_selectedProvince != null) ...[
          const SizedBox(height: 12),
          _buildDropdown(localizations.selectDistrict, _selectedDistrict, RwandaLocation.getDistricts(_selectedProvince!), (v) {
            setState(() {
              _selectedDistrict = v;
              _selectedSector = _selectedCell = _selectedVillage = null;
            });
          }),
        ],
        if (_selectedDistrict != null) ...[
          const SizedBox(height: 12),
          _buildDropdown(localizations.selectSector, _selectedSector, RwandaLocation.getSectors(_selectedProvince!, _selectedDistrict!), (v) {
            setState(() {
              _selectedSector = v;
              _selectedCell = _selectedVillage = null;
            });
          }),
        ],
      ],
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF00A86B)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A86B), width: 2)),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildRegisterButton(AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A86B),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(localizations.register, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginLink(AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(localizations.alreadyHaveAccount, style: TextStyle(color: Colors.grey[600])),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(localizations.login, style: const TextStyle(color: Color(0xFF00A86B), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
