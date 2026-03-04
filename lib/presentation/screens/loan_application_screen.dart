import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class LoanApplicationScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final double totalShares;
  final double shareValue;
  final double interestRate;
  final double maxLoanMultiplier;
  final bool requireGuarantors;
  final int guarantorsRequired;

  const LoanApplicationScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.totalShares,
    required this.shareValue,
    required this.interestRate,
    this.maxLoanMultiplier = 3.0,
    this.requireGuarantors = true,
    this.guarantorsRequired = 2,
  });

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  
  double _loanAmount = 0;
  int _duration = 1;
  String _purpose = '';
  List<String> _selectedGuarantors = [];
  
  late AnimationController _progressController;
  late AnimationController _cardController;
  
  double get maxLoanAmount => widget.totalShares * widget.shareValue * widget.maxLoanMultiplier;
  double get interest => (_loanAmount * widget.interestRate) / 100;
  double get totalRepayment => _loanAmount + interest;
  double get monthlyPayment => totalRepayment / _duration;

  @override
  void initState() {
    super.initState();
    _loanAmount = maxLoanAmount * 0.3;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Loan Application', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_currentStep == 0) _buildLoanAmountStep(),
                    if (_currentStep == 1) _buildLoanDetailsStep(),
                    if (_currentStep == 2) _buildGuarantorsStep(),
                    if (_currentStep == 3) _buildReviewStep(),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF00A86B) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < 3) const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepLabel('Amount', 0),
              _buildStepLabel('Details', 1),
              _buildStepLabel('Guarantors', 2),
              _buildStepLabel('Review', 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String label, int step) {
    final isActive = step == _currentStep;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: isActive ? const Color(0xFF00A86B) : Colors.grey,
      ),
    );
  }

  Widget _buildLoanAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(),
        const SizedBox(height: 24),
        _buildAmountSlider(),
        const SizedBox(height: 24),
        _buildCalculationCard(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A86B), Color(0xFF00D68F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A86B).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Eligibility',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '${maxLoanAmount.toStringAsFixed(0)} RWF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Shares', '${widget.totalShares.toInt()}'),
              ),
              Expanded(
                child: _buildInfoItem('Share Value', '${widget.shareValue.toInt()} RWF'),
              ),
              Expanded(
                child: _buildInfoItem('Interest', '${widget.interestRate}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAmountSlider() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Amount',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${_loanAmount.toStringAsFixed(0)} RWF',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A86B),
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              activeTrackColor: const Color(0xFF00A86B),
              inactiveTrackColor: Colors.grey[200],
              thumbColor: const Color(0xFF00A86B),
              overlayColor: const Color(0xFF00A86B).withOpacity(0.2),
            ),
            child: Slider(
              value: _loanAmount,
              min: widget.shareValue * widget.totalShares,
              max: maxLoanAmount,
              divisions: 20,
              onChanged: (value) {
                setState(() => _loanAmount = value);
                HapticFeedback.selectionClick();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${(widget.shareValue * widget.totalShares).toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                'Max: ${maxLoanAmount.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCalculationRow('Loan Amount', '${_loanAmount.toStringAsFixed(0)} RWF', false),
          const Divider(height: 24),
          _buildCalculationRow('Interest (${widget.interestRate}%)', '${interest.toStringAsFixed(0)} RWF', false),
          const Divider(height: 24),
          _buildCalculationRow('Total Repayment', '${totalRepayment.toStringAsFixed(0)} RWF', true),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isBold ? const Color(0xFF00A86B) : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildLoanDetailsStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loan Duration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [1, 2, 3, 6, 12].map((months) {
                  final isSelected = _duration == months;
                  return InkWell(
                    onTap: () {
                      setState(() => _duration = months);
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00A86B) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00A86B) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$months',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            months == 1 ? 'Month' : 'Months',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A86B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF00A86B)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Monthly Payment: ${monthlyPayment.toStringAsFixed(0)} RWF',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A86B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loan Purpose',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe how you will use this loan...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => _purpose = value,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuarantorsStep() {
    final availableGuarantors = [
      {'id': '1', 'name': 'Jean Mukama', 'shares': 120, 'avatar': 'JM'},
      {'id': '2', 'name': 'Marie Uwase', 'shares': 95, 'avatar': 'MU'},
      {'id': '3', 'name': 'Patrick Niyonzima', 'shares': 150, 'avatar': 'PN'},
      {'id': '4', 'name': 'Grace Mutoni', 'shares': 80, 'avatar': 'GM'},
      {'id': '5', 'name': 'Eric Habimana', 'shares': 110, 'avatar': 'EH'},
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.amber[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select ${widget.guarantorsRequired} guarantors to secure your loan',
                  style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...availableGuarantors.map((guarantor) {
          final isSelected = _selectedGuarantors.contains(guarantor['id']);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF00A86B) : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (_selectedGuarantors.length < widget.guarantorsRequired) {
                      _selectedGuarantors.add(guarantor['id'] as String);
                    }
                  } else {
                    _selectedGuarantors.remove(guarantor['id']);
                  }
                });
                HapticFeedback.selectionClick();
              },
              activeColor: const Color(0xFF00A86B),
              title: Text(
                guarantor['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${guarantor['shares']} shares'),
              secondary: CircleAvatar(
                backgroundColor: const Color(0xFF00A86B),
                child: Text(
                  guarantor['avatar'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00A86B), Color(0xFF00D68F)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A86B).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Review Your Application',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please review all details before submitting',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildReviewCard('Loan Details', [
          {'label': 'Amount', 'value': '${_loanAmount.toStringAsFixed(0)} RWF'},
          {'label': 'Duration', 'value': '$_duration ${_duration == 1 ? 'Month' : 'Months'}'},
          {'label': 'Interest Rate', 'value': '${widget.interestRate}%'},
          {'label': 'Interest Amount', 'value': '${interest.toStringAsFixed(0)} RWF'},
          {'label': 'Total Repayment', 'value': '${totalRepayment.toStringAsFixed(0)} RWF'},
          {'label': 'Monthly Payment', 'value': '${monthlyPayment.toStringAsFixed(0)} RWF'},
        ]),
        const SizedBox(height: 16),
        _buildReviewCard('Guarantors', [
          {'label': 'Selected', 'value': '${_selectedGuarantors.length} guarantors'},
        ]),
      ],
    );
  }

  Widget _buildReviewCard(String title, List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['label']!, style: TextStyle(color: Colors.grey[600])),
                Text(
                  item['value']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                  HapticFeedback.lightImpact();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_currentStep == 3 ? 'Submit Application' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 2 && _selectedGuarantors.length < widget.guarantorsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select ${widget.guarantorsRequired} guarantors'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      HapticFeedback.mediumImpact();
    } else {
      _submitApplication();
    }
  }

  void _submitApplication() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Submitting your application...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF00A86B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Application Submitted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your loan application for ${_loanAmount.toStringAsFixed(0)} RWF has been submitted for approval.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
