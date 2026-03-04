import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class SendMoneyScreen extends StatefulWidget {
  final String userId;
  
  const SendMoneyScreen({super.key, required this.userId});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  
  Map<String, dynamic>? _recipient;
  double _balance = 0;
  bool _loading = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final response = await _dio.get('/wallet', queryParameters: {'userId': widget.userId});
      if (response.statusCode == 200 && mounted) {
        setState(() => _balance = response.data['balance'].toDouble());
      }
    } catch (e) {}
  }

  Future<void> _searchUser() async {
    if (_phoneController.text.isEmpty) return;
    
    setState(() => _searching = true);
    try {
      final response = await _dio.get('/users/search', queryParameters: {'phone': _phoneController.text});
      
      if (response.data['user'] != null && mounted) {
        setState(() {
          _recipient = response.data['user'];
          _searching = false;
        });
      } else {
        throw Exception('Uyu mukoresha ntabwo ahari');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recipient = null;
          _searching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendMoney() async {
    if (_recipient == null || _amountController.text.isEmpty) return;
    
    final amount = double.parse(_amountController.text);
    if (amount > _balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amafaranga ntahagije'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await _dio.post('/transfers', data: {
        'senderId': widget.userId,
        'recipientId': _recipient!['id'],
        'amount': amount,
        'note': _noteController.text,
      });

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amafaranga yoherejwe neza!'), backgroundColor: Colors.green),
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
      appBar: AppBar(title: const Text('Kohereza Amafaranga')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amafaranga yawe:', style: TextStyle(fontSize: 16)),
                    Text('${_balance.toStringAsFixed(0)} RWF', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00A86B))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Nimero ya telefoni y\'uwakira', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '+250 788 123 456',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searching ? null : _searchUser,
                  child: _searching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Shakisha'),
                ),
              ],
            ),
            if (_recipient != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00A86B),
                    child: Text(_recipient!['name'][0], style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(_recipient!['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_recipient!['phone']),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Amafaranga yo kohereza', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixText: 'RWF',
                  hintText: 'Andika amafaranga',
                  prefixIcon: Icon(Icons.money),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Ubutumwa (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Andika ubutumwa...',
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendMoney,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Ohereza Amafaranga', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
