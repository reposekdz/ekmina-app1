import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class AdvancedLoanApplicationScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String userId;
  const AdvancedLoanApplicationScreen({super.key, required this.groupId, required this.userId});

  @override
  ConsumerState<AdvancedLoanApplicationScreen> createState() => _AdvancedLoanApplicationScreenState();
}

class _AdvancedLoanApplicationScreenState extends ConsumerState<AdvancedLoanApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  int _duration = 3;
  double _maxLoanAmount = 150000;
  double _userShares = 50000;
  double _interestRate = 10;
  List<Map<String, dynamic>> _selectedGuarantors = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadEligibility();
  }

  Future<void> _loadEligibility() async {
    // In a real app, fetch this from API
    setState(() {
      _maxLoanAmount = 300000;
      _userShares = 100000;
      _interestRate = 8.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final interest = amount * (_interestRate / 100) * (_duration / 12);
    final totalRepayment = amount + interest;
    final monthlyPayment = _duration > 0 ? totalRepayment / _duration : 0;

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
                        _buildEligibilityCard().animate().fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Amakuru y\'inguzanyo', LucideIcons.landmark),
                        _buildLoanFormCard(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Abishingizi (Guarantors)', LucideIcons.users),
                        _buildGuarantorsCard(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Incamake yo kwishyura', LucideIcons.calculator),
                        _buildSummaryCard(interest, totalRepayment, monthlyPayment),
                        const SizedBox(height: 48),
                        _buildSubmitButton().animate().fadeIn(delay: 400.ms).scale(),
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
              Text('Saba Inguzanyo', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Uzuza ubusabe bwawe hano', style: TextStyle(color: Colors.white70, fontSize: 14)),
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

  Widget _buildEligibilityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00D68F)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF00A86B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Icyerekezo cy\'inguzanyo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _buildEligibilityRow('Imigabane yawe', Formatters.formatCurrency(_userShares)),
          _buildEligibilityRow('Inguzanyo ntarengwa', Formatters.formatCurrency(_maxLoanAmount)),
          _buildEligibilityRow('Inyungu ku mwaka', '$_interestRate%'),
          _buildEligibilityRow('Abishingizi bakenewe', '2'),
        ],
      ),
    );
  }

  Widget _buildEligibilityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLoanFormCard() {
    return _buildCard([
      TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        decoration: InputDecoration(
          labelText: 'Umubare w\'amafaranga (RWF)',
          prefixIcon: const Icon(LucideIcons.banknote),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        validator: (v) {
          if (v?.isEmpty ?? true) return 'Injiza amafaranga';
          final val = double.tryParse(v!);
          if (val == null || val <= 0) return 'Injiza amafaranga mazima';
          if (val > _maxLoanAmount) return 'Warengeje inguzanyo wemerewe';
          return null;
        },
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Igihe cyo kwishyura', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('$_duration Amezi', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      Slider(
        value: _duration.toDouble(),
        min: 1,
        max: 12,
        divisions: 11,
        activeColor: AppTheme.primaryBlue,
        onChanged: (v) => setState(() => _duration = v.toInt()),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _purposeController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Impamvu usaba inguzanyo',
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        validator: (v) => v?.isEmpty ?? true ? 'Injiza impamvu' : null,
      ),
    ]);
  }

  Widget _buildGuarantorsCard() {
    return _buildCard([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Abishingizi batoranyijwe', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${_selectedGuarantors.length}/2', style: TextStyle(color: _selectedGuarantors.length < 2 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 16),
      ..._selectedGuarantors.map((g) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const CircleAvatar(radius: 16, backgroundColor: AppTheme.primaryBlue, child: Icon(LucideIcons.user, size: 16, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
            IconButton(icon: const Icon(LucideIcons.x, size: 18, color: Colors.red), onPressed: () => setState(() => _selectedGuarantors.remove(g))),
          ],
        ),
      )),
      if (_selectedGuarantors.length < 2)
        OutlinedButton.icon(
          onPressed: _showGuarantorSelection,
          icon: const Icon(LucideIcons.userPlus, size: 18),
          label: const Text('Ongeraho umushingizi'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
    ]);
  }

  Widget _buildSummaryCard(double interest, double total, double monthly) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Inguzanyo', Formatters.formatCurrency(double.tryParse(_amountController.text) ?? 0)),
          _buildSummaryRow('Inyungu ($_interestRate%)', Formatters.formatCurrency(interest)),
          const Divider(height: 32),
          _buildSummaryRow('Igiteranyo cyose', Formatters.formatCurrency(total), color: AppTheme.primaryBlue, isBold: true),
          _buildSummaryRow('Kwishyura buri kwezi', Formatters.formatCurrency(monthly), color: Colors.green, isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final bool isValid = _selectedGuarantors.length >= 2 && _amountController.text.isNotEmpty;
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: isValid && !_loading ? AppTheme.primaryGradient : null,
        color: !isValid || _loading ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isValid && !_loading ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))] : null,
      ),
      child: ElevatedButton(
        onPressed: isValid && !_loading ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: _loading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('OHEREZA UBUSABE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  void _showGuarantorSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hitamo Umushingizi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            // Mock members for now
            _buildGuarantorItem('John Kabera', 'Shares: 200K RWF'),
            _buildGuarantorItem('Alice Uwera', 'Shares: 150K RWF'),
            _buildGuarantorItem('Peter Mugisha', 'Shares: 300K RWF'),
          ],
        ),
      ),
    );
  }

  Widget _buildGuarantorItem(String name, String sub) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(LucideIcons.user)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      onTap: () {
        setState(() => _selectedGuarantors.add({'name': name, 'id': 'temp_id'}));
        Navigator.pop(context);
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.applyForLoan(
        widget.groupId, 
        double.parse(_amountController.text), 
        _purposeController.text, 
        _selectedGuarantors.map((g) => g['id'] as String).toList(), 
        _duration,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubusabe bwawe bwoherejwe neza!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ikosa ryabaye mu kohereza ubusabe'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
