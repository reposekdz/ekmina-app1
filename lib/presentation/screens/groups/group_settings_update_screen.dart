import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class GroupSettingsUpdateScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  final Map<String, dynamic> currentSettings;
  
  const GroupSettingsUpdateScreen({super.key, required this.groupId, required this.userId, required this.currentSettings});

  @override
  State<GroupSettingsUpdateScreen> createState() => _GroupSettingsUpdateScreenState();
}

class _GroupSettingsUpdateScreenState extends State<GroupSettingsUpdateScreen> {
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shareValueController;
  late TextEditingController _joinFeeController;
  late TextEditingController _penaltyController;
  late TextEditingController _loanInterestController;
  bool _loading = false;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _shareValueController = TextEditingController(text: widget.currentSettings['shareValue'].toString());
    _joinFeeController = TextEditingController(text: widget.currentSettings['joinFee'].toString());
    _penaltyController = TextEditingController(text: widget.currentSettings['penaltyAmount'].toString());
    _loanInterestController = TextEditingController(text: widget.currentSettings['loanInterestRate'].toString());
    _checkIfLocked();
  }

  Future<void> _checkIfLocked() async {
    try {
      final response = await _dio.get('/groups/${widget.groupId}/settings-lock');
      if (response.statusCode == 200 && mounted) {
        setState(() => _isLocked = response.data['isLocked'] ?? false);
      }
    } catch (e) {}
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Igenamiterere ryafunzwe na Admin mukuru. Ntushobora guhindura.'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emeza impinduka'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Urashaka kohereza icyifuzo cyo guhindura igenamiterere?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Impinduka zikeneye kwemezwa na:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('• Abayobozi 2 cyangwa 3', style: TextStyle(fontSize: 11)),
                  const Text('• Bazahamagariwa kugirango bemeze', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hagarika')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yego, ohereza')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final response = await _dio.post('/groups/${widget.groupId}/settings-update-request', data: {
        'userId': widget.userId,
        'changes': {
          'shareValue': double.parse(_shareValueController.text),
          'joinFee': double.parse(_joinFeeController.text),
          'penaltyAmount': double.parse(_penaltyController.text),
          'loanInterestRate': double.parse(_loanInterestController.text),
        }
      });

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Icyifuzo cyoherejwe. Tegereza kwemezwa.'), backgroundColor: Colors.green),
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
      appBar: AppBar(
        title: const Text('Hindura igenamiterere'),
        actions: [
          if (_isLocked)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Chip(
                avatar: const Icon(Icons.lock, size: 16, color: Colors.white),
                label: const Text('Ryafunzwe', style: TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: Colors.red,
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLocked)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Igenamiterere ryafunzwe', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                          const SizedBox(height: 4),
                          Text('Admin mukuru yafunze igenamiterere. Ntushobora guhindura.', style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amafaranga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _shareValueController,
                      decoration: const InputDecoration(labelText: 'Agaciro k\'imigabane (RWF)', prefixIcon: Icon(Icons.money)),
                      keyboardType: TextInputType.number,
                      enabled: !_isLocked,
                      validator: (v) => v?.isEmpty ?? true ? 'Byasabwa' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _joinFeeController,
                      decoration: const InputDecoration(labelText: 'Amafaranga yo kwinjira (RWF)', prefixIcon: Icon(Icons.payment)),
                      keyboardType: TextInputType.number,
                      enabled: !_isLocked,
                      validator: (v) => v?.isEmpty ?? true ? 'Byasabwa' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _penaltyController,
                      decoration: const InputDecoration(labelText: 'Ihano (RWF)', prefixIcon: Icon(Icons.warning)),
                      keyboardType: TextInputType.number,
                      enabled: !_isLocked,
                      validator: (v) => v?.isEmpty ?? true ? 'Byasabwa' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _loanInterestController,
                      decoration: const InputDecoration(labelText: 'Inyungu z\'inguzanyo (%)', prefixIcon: Icon(Icons.percent)),
                      keyboardType: TextInputType.number,
                      enabled: !_isLocked,
                      validator: (v) => v?.isEmpty ?? true ? 'Byasabwa' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text('Amakuru', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Impinduka zikeneye kwemezwa na abayobozi 2-3', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('• Bazahamagariwa kugirango bemeze', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('• Impinduka zizakorwa nyuma yo kwemezwa', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading || _isLocked ? null : _submitUpdate,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ohereza icyifuzo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shareValueController.dispose();
    _joinFeeController.dispose();
    _penaltyController.dispose();
    _loanInterestController.dispose();
    super.dispose();
  }
}
