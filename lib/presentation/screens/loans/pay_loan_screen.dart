import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class PayLoanScreen extends StatefulWidget {
  final String loanId;
  final String groupName;
  final double remainingAmount;
  final String userId;
  
  const PayLoanScreen({super.key, required this.loanId, required this.groupName, required this.remainingAmount, required this.userId});

  @override
  State<PayLoanScreen> createState() => _PayLoanScreenState();
}

class _PayLoanScreenState extends State<PayLoanScreen> {
  final _amountController = TextEditingController();
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  bool _loading = false;
  String _paymentMethod = 'WALLET';

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.remainingAmount.toStringAsFixed(0);
  }

  Future<void> _payLoan() async {
    if (_amountController.text.isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final response = await _dio.post('/loans/${widget.loanId}/payment', data: {
        'userId': widget.userId,
        'amount': double.parse(_amountController.text),
        'paymentMethod': _paymentMethod,
      });

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inguzanyo yishyuwe neza!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kwishyura Inguzanyo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Itsinda: ${widget.groupName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Asigaye: ${widget.remainingAmount.toStringAsFixed(0)} RWF', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Amafaranga yo kwishyura', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: 'RWF',
                hintText: 'Andika amafaranga',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Uburyo bwo kwishyura', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioListTile(
              title: const Text('Amafaranga yanjye'),
              value: 'WALLET',
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            RadioListTile(
              title: const Text('MTN Mobile Money'),
              value: 'MTN_MOMO',
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            RadioListTile(
              title: const Text('Airtel Money'),
              value: 'AIRTEL_MONEY',
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _payLoan,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Ishyura', style: TextStyle(fontSize: 16)),
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
    super.dispose();
  }
}
