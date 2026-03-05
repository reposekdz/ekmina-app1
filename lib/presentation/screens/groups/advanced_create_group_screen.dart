import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/rwanda_location.dart';

class AdvancedCreateGroupScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdvancedCreateGroupScreen({super.key, required this.userId});

  @override
  ConsumerState<AdvancedCreateGroupScreen> createState() => _AdvancedCreateGroupScreenState();
}

class _AdvancedCreateGroupScreenState extends ConsumerState<AdvancedCreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _shareValueController = TextEditingController();
  final _joinFeeController = TextEditingController();
  final _penaltyController = TextEditingController();
  final _latePenaltyController = TextEditingController();
  final _loanInterestController = TextEditingController();
  
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSector;
  
  String _contributionFreq = 'WEEKLY';
  String _penaltyType = 'FIXED';
  int _collectionDay = 1;
  String _collectionTime = '16:00';
  bool _isPublic = true;
  bool _loading = false;
  double _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getWallet(widget.userId);
      if (mounted) {
        setState(() => _walletBalance = (response['wallet']?['balance'] ?? 0).toDouble());
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryBlue, Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppTheme.lightBg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildFeeStatusCard().animate().fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Ibisobanuro by\'itsinda', LucideIcons.info),
                        _buildBasicInfoCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Aho riherereye', LucideIcons.mapPin),
                        _buildLocationCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Igenamiterere ry\'amafaranga', LucideIcons.banknote),
                        _buildFinancialCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Igihe cyo gutanga', LucideIcons.calendar),
                        _buildScheduleCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Ibihano n\'inguzanyo', LucideIcons.shieldAlert),
                        _buildRiskCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Umutekano', LucideIcons.eye),
                        _buildVisibilityCard(),
                        const SizedBox(height: 48),
                        _buildCreateButton().animate().fadeIn(delay: 400.ms).scale(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kurema Itsinda', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Tangira Ikimina gishya', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildFeeStatusCard() {
    final bool canAfford = _walletBalance >= 2000;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: canAfford ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: canAfford ? Colors.green.shade100 : Colors.red.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: canAfford ? Colors.green : Colors.red, shape: BoxShape.circle),
            child: Icon(canAfford ? LucideIcons.check : LucideIcons.alertCircle, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ikiguzi: 2,000 RWF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Balance: ${Formatters.formatCurrency(_walletBalance)}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildCard([
      _buildTextField(_nameController, 'Izina ry\'itsinda *', LucideIcons.users, validator: (v) => v?.isEmpty ?? true ? 'Injiza izina' : null),
      const SizedBox(height: 16),
      _buildTextField(_descController, 'Ibisobanuro', LucideIcons.alignLeft, maxLines: 3),
    ]);
  }

  Widget _buildLocationCard() {
    return _buildCard([
      _buildDropdown('Intara', _selectedProvince, RwandaLocation.getProvinces(), (v) {
        setState(() {
          _selectedProvince = v;
          _selectedDistrict = _selectedSector = null;
        });
      }),
      const SizedBox(height: 12),
      if (_selectedProvince != null)
        _buildDropdown('Akarere', _selectedDistrict, RwandaLocation.getDistricts(_selectedProvince!), (v) {
          setState(() {
            _selectedDistrict = v;
            _selectedSector = null;
          });
        }),
      const SizedBox(height: 12),
      if (_selectedDistrict != null)
        _buildDropdown('Umurenge', _selectedSector, RwandaLocation.getSectors(_selectedProvince!, _selectedDistrict!), (v) {
          setState(() => _selectedSector = v);
        }),
    ]);
  }

  Widget _buildFinancialCard() {
    return _buildCard([
      _buildTextField(_shareValueController, 'Agaciro k\'umugabane (RWF) *', LucideIcons.coins, keyboard: TextInputType.number),
      const SizedBox(height: 16),
      _buildTextField(_joinFeeController, 'Amafaranga yo kwinjira (RWF) *', LucideIcons.wallet, keyboard: TextInputType.number),
    ]);
  }

  Widget _buildScheduleCard() {
    return _buildCard([
      _buildDropdown('Inshuro yo gutanga', _contributionFreq, ['DAILY', 'WEEKLY', 'MONTHLY'], (v) => setState(() => _contributionFreq = v!)),
      const SizedBox(height: 12),
      if (_contributionFreq == 'WEEKLY')
        _buildDropdown('Umunsi wo gukusanya', _collectionDay.toString(), List.generate(7, (i) => (i + 1).toString()), (v) => setState(() => _collectionDay = int.parse(v!))),
    ]);
  }

  Widget _buildRiskCard() {
    return _buildCard([
      _buildTextField(_loanInterestController, 'Inyungu ku nguzanyo (%)', LucideIcons.percent, keyboard: TextInputType.number),
      const SizedBox(height: 16),
      _buildTextField(_penaltyController, 'Ihano ryo gutinda (RWF)', LucideIcons.alertTriangle, keyboard: TextInputType.number),
    ]);
  }

  Widget _buildVisibilityCard() {
    return _buildCard([
      SwitchListTile(
        title: const Text('Itsinda riragaragara', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Abandi babona itsinda ryawe riri mu rutonde', style: TextStyle(fontSize: 12)),
        value: _isPublic,
        onChanged: (v) => setState(() => _isPublic = v),
        activeColor: AppTheme.primaryBlue,
      ),
    ]);
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboard, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _handleCreate,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: _loading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('KORA ITSINDA (2,000 RWF)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_walletBalance < 2000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shyiramo amafaranga kuri wallet yawe mbere')));
      return;
    }

    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.createGroup({
        'name': _nameController.text,
        'description': _descController.text,
        'province': _selectedProvince,
        'district': _selectedDistrict,
        'sector': _selectedSector,
        'shareValue': double.parse(_shareValueController.text),
        'joinFee': double.parse(_joinFeeController.text),
        'loanInterestRate': double.parse(_loanInterestController.text.isEmpty ? '0' : _loanInterestController.text),
        'penaltyAmount': double.parse(_penaltyController.text.isEmpty ? '0' : _penaltyController.text),
        'isPublic': _isPublic,
        'creatorId': widget.userId,
      });
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itsinda ryakozwe neza!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ikosa ryabaye'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
