import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/fraud_detection_service.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import 'wallet_pin_screen.dart';

class WithdrawMoneyScreen extends StatefulWidget {
  final double walletBalance;

  const WithdrawMoneyScreen({Key? key, required this.walletBalance}) : super(key: key);

  @override
  State<WithdrawMoneyScreen> createState() => _WithdrawMoneyScreenState();
}

class _WithdrawMoneyScreenState extends State<WithdrawMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiClient = ApiClient();
  final _fraudService = FraudDetectionService();
  
  String _selectedProvider = 'MTN';
  bool _isLoading = false;
  String? _pin;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    setState(() => _userId = 'current-user-id'); // Replace with actual user ID
  }

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) return;

    // Request PIN
    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const WalletPinScreen(mode: 'verify'),
      ),
    );

    if (pin == null) return;

    setState(() {
      _isLoading = true;
      _pin = pin;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final phone = _phoneController.text.trim();

      final response = await _apiClient.withdraw(
        _userId!,
        amount,
        _selectedProvider,
        pin,
        phone: phone,
      );

      // Check fraud detection
      final fraudCheck = _fraudService.analyzeFraudCheck(
        response['transaction']['metadata']?['fraudCheck'],
      );

      if (fraudCheck['shouldBlock']) {
        throw Exception(_fraudService.getBlockedTransactionMessage('rw'));
      }

      if (fraudCheck['shouldWarn']) {
        final proceed = await _showFraudWarning(fraudCheck);
        if (!proceed) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amafaranga yasohowe neza'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showFraudWarning(Map<String, dynamic> fraudCheck) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(int.parse(
                _fraudService.getRiskLevelColor(fraudCheck['riskLevel']).replaceAll('#', '0xFF'),
              )),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Burira!')),
          ],
        ),
        content: Text(
          _fraudService.getRiskWarningMessage(
            fraudCheck['riskLevel'],
            List<String>.from(fraudCheck['reasons']),
            'rw',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hagarika'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Komeza'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohora Amafaranga'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Amafaranga yawe',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatCurrency(widget.walletBalance),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hitamo uburyo bwo kwakira',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProviderCard('MTN', 'assets/images/mtn_logo.png'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildProviderCard('AIRTEL', 'assets/images/airtel_logo.png'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amafaranga',
                  hintText: 'Shyiramo amafaranga',
                  prefixText: 'RWF ',
                  border: const OutlineInputBorder(),
                  helperText: 'Max: ${Formatters.formatCurrency(widget.walletBalance)}',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) return newValue;
                    final value = int.parse(newValue.text);
                    final formatted = Formatters.formatNumber(value.toDouble());
                    return TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Shyiramo amafaranga';
                  }
                  final amount = double.parse(value.replaceAll(',', ''));
                  if (amount < 100) {
                    return 'Amafaranga agomba kuba angana na 100 RWF cyangwa arenga';
                  }
                  if (amount > widget.walletBalance) {
                    return 'Ntufite amafaranga ahagije';
                  }
                  if (amount > 5000000) {
                    return 'Ntushobora gusohora arenga 5,000,000 RWF';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomero ya telefoni',
                  hintText: '078XXXXXXX',
                  prefixText: '+250 ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Shyiramo nomero ya telefoni';
                  }
                  if (value.length != 9) {
                    return 'Nomero ya telefoni igomba kuba imibare 9';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Uzasabwa PIN yawe kugirango wemeze',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleWithdraw,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Sohora Amafaranga',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(String provider, String logoPath) {
    final isSelected = _selectedProvider == provider;
    return InkWell(
      onTap: () => setState(() => _selectedProvider = provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.orange[50] : null,
        ),
        child: Column(
          children: [
            Image.asset(
              logoPath,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.payment,
                  size: 40,
                  color: isSelected ? Colors.orange : Colors.grey,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              provider,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.orange : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
