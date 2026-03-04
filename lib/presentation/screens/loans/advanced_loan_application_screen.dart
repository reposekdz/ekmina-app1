import 'package:flutter/material.dart';

class AdvancedLoanApplicationScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  const AdvancedLoanApplicationScreen({super.key, required this.groupId, required this.userId});

  @override
  State<AdvancedLoanApplicationScreen> createState() => _AdvancedLoanApplicationScreenState();
}

class _AdvancedLoanApplicationScreenState extends State<AdvancedLoanApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  int _duration = 3;
  double _maxLoanAmount = 150000;
  double _userShares = 50000;
  double _interestRate = 10;
  List<String> _selectedGuarantors = [];
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final interest = (double.tryParse(_amountController.text) ?? 0) * (_interestRate / 100);
    final totalRepayment = (double.tryParse(_amountController.text) ?? 0) + interest;
    final monthlyPayment = _duration > 0 ? totalRepayment / _duration : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Loan'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildEligibilityCard(),
            const SizedBox(height: 20),
            _buildLoanAmountSection(),
            const SizedBox(height: 20),
            _buildDurationSection(),
            const SizedBox(height: 20),
            _buildPurposeSection(),
            const SizedBox(height: 20),
            _buildGuarantorsSection(),
            const SizedBox(height: 20),
            _buildSummaryCard(interest, totalRepayment, monthlyPayment.toDouble()),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00D68F)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Loan Eligibility', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildEligibilityRow('Your Shares', '${_userShares.toStringAsFixed(0)} RWF'),
          _buildEligibilityRow('Max Loan Amount', '${_maxLoanAmount.toStringAsFixed(0)} RWF'),
          _buildEligibilityRow('Interest Rate', '$_interestRate%'),
          _buildEligibilityRow('Required Guarantors', '2 members'),
        ],
      ),
    );
  }

  Widget _buildEligibilityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLoanAmountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loan Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (RWF)',
                prefixIcon: const Icon(Icons.money),
                helperText: 'Maximum: ${_maxLoanAmount.toStringAsFixed(0)} RWF',
              ),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                final amount = double.tryParse(v!);
                if (amount == null || amount <= 0) return 'Invalid amount';
                if (amount > _maxLoanAmount) return 'Exceeds maximum';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Repayment Duration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('$_duration months', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _duration > 1 ? () => setState(() => _duration--) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _duration < 12 ? () => setState(() => _duration++) : null,
                ),
              ],
            ),
            Slider(
              value: _duration.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '$_duration months',
              activeColor: const Color(0xFF00A86B),
              onChanged: (v) => setState(() => _duration = v.toInt()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loan Purpose', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _purposeController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe the purpose of this loan',
                hintText: 'e.g., Business expansion, education, emergency...',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuarantorsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Guarantors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_selectedGuarantors.length}/2', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            ..._selectedGuarantors.map((g) => _buildGuarantorChip(g)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showGuarantorSelection,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Guarantor'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuarantorChip(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00A86B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _selectedGuarantors.remove(name)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double interest, double total, double monthly) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Loan Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _buildSummaryRow('Loan Amount', _amountController.text.isEmpty ? '0 RWF' : '${_amountController.text} RWF'),
          _buildSummaryRow('Interest ($_interestRate%)', '${interest.toStringAsFixed(0)} RWF'),
          _buildSummaryRow('Total Repayment', '${total.toStringAsFixed(0)} RWF'),
          _buildSummaryRow('Monthly Payment', '${monthly.toStringAsFixed(0)} RWF'),
          _buildSummaryRow('Duration', '$_duration months'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _loading ? null : _submitLoanApplication,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00A86B),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _loading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  void _showGuarantorSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Guarantor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('John Doe'),
              onTap: () {
                if (_selectedGuarantors.length < 2) {
                  setState(() => _selectedGuarantors.add('John Doe'));
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitLoanApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGuarantors.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 guarantors')),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan application submitted successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }
}
