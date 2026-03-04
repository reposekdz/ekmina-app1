import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class RequestLoanScreen extends ConsumerStatefulWidget {
  final String groupId;
  const RequestLoanScreen({super.key, required this.groupId});

  @override
  ConsumerState<RequestLoanScreen> createState() => _RequestLoanScreenState();
}

class _RequestLoanScreenState extends ConsumerState<RequestLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();

  int _duration = 3;
  double _maxLoanAmount = 0;
  double _userShares = 0;
  double _interestRate = 0;
  bool _loading = true;
  String? _userId;
  List<dynamic> _groupMembers = [];
  List<String> _selectedGuarantors = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final storage = SecureStorageService();
      _userId = await storage.getUserId();
      if (_userId == null) return;

      final api = ref.read(apiClientProvider);
      final groupData = await api.getGroupDetails(widget.groupId, _userId!);
      final membershipData = await api.getGroupMembership(widget.groupId, _userId!);
      final membersData = await api.getGroupMembers(widget.groupId);

      if (mounted) {
        final group = groupData['group'];
        final membership = membershipData['membership'];

        setState(() {
          _userShares = (membership['totalShares'] ?? 0).toDouble();
          _interestRate = (group['loanInterestRate'] ?? 0).toDouble();
          // Eligibility rule: Max 3x shares or group defined max
          _maxLoanAmount = _userShares * 3;
          _groupMembers = (membersData['members'] as List? ?? []).where((m) => m['userId'] != _userId).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGuarantors.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ugomba guhitamo abishingizi 2'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.requestLoan({
        'groupId': widget.groupId,
        'userId': _userId,
        'amount': double.parse(_amountController.text),
        'duration': _duration,
        'purpose': _purposeController.text,
        'guarantors': _selectedGuarantors,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubusabe bwawe bwoherejwe neza!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        app_bar: AppBar(title: const Text('Gusaba Inguzanyo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    final interest = amount * (_interestRate / 100) * (_duration / 12);
    final totalRepayment = amount + interest;

    return Scaffold(
      appBar: AppBar(title: const Text('Saba Inguzanyo', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildEligibilityBanner(),
            const SizedBox(height: 24),
            _buildAmountInput(),
            const SizedBox(height: 20),
            _buildDurationPicker(),
            const SizedBox(height: 20),
            _buildPurposeInput(),
            const SizedBox(height: 20),
            _buildGuarantorsSection(),
            const SizedBox(height: 24),
            _buildLoanSummary(interest, totalRepayment),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilityBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryGreen, Color(0xFF00D68F)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ubushobozi bwawe', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEligibilityInfo('Imigabane yawe', Formatters.formatCurrency(_userShares)),
              _buildEligibilityInfo('Inguzanyo yemewe', Formatters.formatCurrency(_maxLoanAmount)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inguzanyo wifuza', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Urugero: 50,000',
            suffixText: 'RWF',
            prefixIcon: const Icon(Icons.money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ugomba kwerekana amafaranga';
            final val = double.tryParse(v);
            if (val == null || val <= 0) return 'Ayakora ntabwo ariyo';
            if (val > _maxLoanAmount) return 'Inguzanyo irenze iyemewe';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Igihe cyo kwishyura: $_duration amezi', style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: _duration.toDouble(),
          min: 1,
          max: 12,
          divisions: 11,
          activeColor: AppTheme.primaryGreen,
          label: '$_duration amezi',
          onChanged: (v) => setState(() => _duration = v.toInt()),
        ),
      ],
    );
  }

  Widget _buildPurposeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Impamvu y\'inguzanyo', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _purposeController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Eleza icyo uzakoresha aya mafaranga...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Ugomba kwerekana impamvu' : null,
        ),
      ],
    );
  }

  Widget _buildGuarantorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Abishingizi (Bakenewe 2)', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${_selectedGuarantors.length}/2', style: TextStyle(color: _selectedGuarantors.length == 2 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedGuarantors.isEmpty)
          const Text('Nta muntu uratoranya', style: TextStyle(color: Colors.grey, fontSize: 12))
        else
          Wrap(
            spacing: 8,
            children: _selectedGuarantors.map((id) {
              final member = _groupMembers.firstWhere((m) => m['userId'] == id);
              return Chip(
                label: Text(member['user']['name'], style: const TextStyle(fontSize: 12)),
                onDeleted: () => setState(() => _selectedGuarantors.remove(id)),
                deleteIconColor: Colors.red,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showGuarantorPicker,
          icon: const Icon(Icons.person_add),
          label: const Text('Guhitamo Umushingizi'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _showGuarantorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hitamo Abishingizi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _groupMembers.length,
                  itemBuilder: (context, index) {
                    final member = _groupMembers[index];
                    final userId = member['userId'] as String;
                    final isSelected = _selectedGuarantors.contains(userId);

                    return CheckboxListTile(
                      title: Text(member['user']['name']),
                      subtitle: Text(member['user']['phone']),
                      value: isSelected,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (val) {
                        if (val == true && _selectedGuarantors.length >= 2) return;
                        setModalState(() {
                          if (val == true) {
                            _selectedGuarantors.add(userId);
                          } else {
                            _selectedGuarantors.remove(userId);
                          }
                        });
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, minimumSize: const Size(double.infinity, 50)),
                child: const Text('BYARANGIYE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanSummary(double interest, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Inguzanyo', Formatters.formatCurrency(double.tryParse(_amountController.text) ?? 0)),
          _buildSummaryRow('Inyungu ($_interestRate%)', Formatters.formatCurrency(interest)),
          const Divider(height: 24),
          _buildSummaryRow('Yose hamwe', Formatters.formatCurrency(total), isBold: true),
          _buildSummaryRow('Ukwezi', Formatters.formatCurrency(total / _duration)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.black : Colors.grey[700], fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _submitApplication,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('OHEREZA UBUSABE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }
}
