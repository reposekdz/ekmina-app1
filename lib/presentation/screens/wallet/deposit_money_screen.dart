import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';

class DepositMoneyScreen extends StatefulWidget {
  const DepositMoneyScreen({Key? key}) : super(key: key);

  @override
  State<DepositMoneyScreen> createState() => _DepositMoneyScreenState();
}

class _DepositMoneyScreenState extends State<DepositMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiClient = ApiClient();
  
  String _selectedProvider = 'MTN';
  bool _isLoading = false;
  String? _transactionId;
  String? _transactionStatus;
  String? _userId;

  final double _minAmount = 100;
  final double _maxAmount = 5000000;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    // Get userId from storage or auth state
    setState(() => _userId = 'current-user-id'); // Replace with actual user ID
  }

  Future<void> _handleDeposit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final phone = _phoneController.text.trim();

      final response = await _apiClient.deposit(
        _userId!,
        amount,
        _selectedProvider,
        phone: phone,
      );

      setState(() {
        _transactionId = response['transaction']['id'];
        _transactionStatus = response['transaction']['status'];
      });

      if (mounted) {
        _showStatusDialog();
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

  void _showStatusDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (_transactionStatus == 'PROCESSING')
              const CircularProgressIndicator()
            else if (_transactionStatus == 'COMPLETED')
              const Icon(Icons.check_circle, color: Colors.green, size: 32)
            else
              const Icon(Icons.error, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _transactionStatus == 'PROCESSING'
                    ? 'Irategerezwa...'
                    : _transactionStatus == 'COMPLETED'
                        ? 'Byagenze neza!'
                        : 'Byanze',
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_transactionStatus == 'PROCESSING') ...[
              const Text('Emeza kuri telefoni yawe'),
              const SizedBox(height: 16),
              Text(
                'Kanda *182*7# (MTN) cyangwa *500# (Airtel) kugirango wemeze',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ] else if (_transactionStatus == 'COMPLETED') ...[
              const Text('Amafaranga yinjiye muri wallet yawe'),
              const SizedBox(height: 8),
              Text(
                'Reference: $_transactionId',
                style: const TextStyle(fontSize: 12),
              ),
            ] else ...[
              const Text('Transaction yanze. Gerageza ukundi.'),
            ],
          ],
        ),
        actions: [
          if (_transactionStatus != 'PROCESSING')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (_transactionStatus == 'COMPLETED') {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Siga'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shyiramo Amafaranga'),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hitamo uburyo bwo kwishyura',
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
                  helperText: 'Min: ${Formatters.formatCurrency(_minAmount)} - Max: ${Formatters.formatCurrency(_maxAmount)}',
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
                  if (amount < _minAmount) {
                    return 'Amafaranga agomba kuba angana na ${Formatters.formatCurrency(_minAmount)} cyangwa arenga';
                  }
                  if (amount > _maxAmount) {
                    return 'Amafaranga ntashobora kurenga ${Formatters.formatCurrency(_maxAmount)}';
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
                  if (_selectedProvider == 'MTN' && !value.startsWith('78')) {
                    return 'MTN MoMo igomba gutangira na 078';
                  }
                  if (_selectedProvider == 'AIRTEL' && !value.startsWith('73')) {
                    return 'Airtel Money igomba gutangira na 073';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Amakuru',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Uzahabwa code kuri telefoni yawe\n'
                      '• Emeza code kugirango transaction irangire\n'
                      '• Amafaranga azinjira muri wallet yawe ako kanya',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleDeposit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Shyiramo Amafaranga',
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
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue[50] : null,
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
                  color: isSelected ? Colors.blue : Colors.grey,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              provider,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black,
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
