import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class AdvancedCreateGroupScreen extends StatefulWidget {
  final String userId;
  const AdvancedCreateGroupScreen({super.key, required this.userId});

  @override
  State<AdvancedCreateGroupScreen> createState() => _AdvancedCreateGroupScreenState();
}

class _AdvancedCreateGroupScreenState extends State<AdvancedCreateGroupScreen> {
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _shareValueController = TextEditingController();
  final _joinFeeController = TextEditingController();
  final _penaltyController = TextEditingController();
  final _latePenaltyController = TextEditingController();
  final _loanInterestController = TextEditingController();
  
  String _province = 'Kigali';
  String _district = 'Gasabo';
  String _sector = 'Remera';
  String _cell = 'Rukiri I';
  String _village = 'Amahoro';
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
      final response = await _dio.get('/wallet', queryParameters: {'userId': widget.userId});
      if (response.statusCode == 200 && mounted) {
        setState(() => _walletBalance = response.data['balance'].toDouble());
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Ikimina Group'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFeeNotice(),
            const SizedBox(height: 20),
            _buildBasicInfo(),
            const SizedBox(height: 20),
            _buildFinancialSettings(),
            const SizedBox(height: 20),
            _buildContributionSettings(),
            const SizedBox(height: 20),
            _buildPenaltySettings(),
            const SizedBox(height: 20),
            _buildLoanSettings(),
            const SizedBox(height: 20),
            _buildVisibilitySettings(),
            const SizedBox(height: 30),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amafaranga yo gukora itsinda: 2,000 RWF', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                const SizedBox(height: 4),
                Text('Wallet yawe: ${_walletBalance.toStringAsFixed(0)} RWF', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Amakuru y\'ibanze', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Izina ry\'itsinda *', prefixIcon: Icon(Icons.group)),
              validator: (v) => v?.isEmpty ?? true ? 'Byasabwa' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Ibisobanuro', prefixIcon: Icon(Icons.description)),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Igenamiterere ry\'amafaranga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shareValueController,
              decoration: const InputDecoration(labelText: 'Agaciro k\'imigabane (RWF) *', prefixIcon: Icon(Icons.money)),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Byasabwa' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _joinFeeController,
              decoration: const InputDecoration(labelText: 'Amafaranga yo kwinjira (RWF) *', prefixIcon: Icon(Icons.payment)),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Byasabwa' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contribution Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _contributionFreq,
              decoration: const InputDecoration(labelText: 'Contribution Frequency', prefixIcon: Icon(Icons.calendar_today)),
              items: const [
                DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                DropdownMenuItem(value: 'BIWEEKLY', child: Text('Bi-Weekly')),
                DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => _contributionFreq = v!),
            ),
            const SizedBox(height: 12),
            if (_contributionFreq == 'WEEKLY')
              DropdownButtonFormField<int>(
                value: _collectionDay,
                decoration: const InputDecoration(labelText: 'Collection Day', prefixIcon: Icon(Icons.event)),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Monday')),
                  DropdownMenuItem(value: 2, child: Text('Tuesday')),
                  DropdownMenuItem(value: 3, child: Text('Wednesday')),
                  DropdownMenuItem(value: 4, child: Text('Thursday')),
                  DropdownMenuItem(value: 5, child: Text('Friday')),
                  DropdownMenuItem(value: 6, child: Text('Saturday')),
                  DropdownMenuItem(value: 7, child: Text('Sunday')),
                ],
                onChanged: (v) => setState(() => _collectionDay = v!),
              ),
            if (_contributionFreq == 'MONTHLY')
              DropdownButtonFormField<int>(
                value: _collectionDay,
                decoration: const InputDecoration(labelText: 'Collection Day of Month', prefixIcon: Icon(Icons.event)),
                items: List.generate(28, (i) => DropdownMenuItem(value: i + 1, child: Text('Day ${i + 1}'))),
                onChanged: (v) => setState(() => _collectionDay = v!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPenaltySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Penalty Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _penaltyType,
              decoration: const InputDecoration(labelText: 'Penalty Type', prefixIcon: Icon(Icons.warning)),
              items: const [
                DropdownMenuItem(value: 'FIXED', child: Text('Fixed Amount')),
                DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage')),
              ],
              onChanged: (v) => setState(() => _penaltyType = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _penaltyController,
              decoration: InputDecoration(
                labelText: _penaltyType == 'FIXED' ? 'Penalty Amount (RWF)' : 'Penalty Percentage (%)',
                prefixIcon: const Icon(Icons.money_off),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _latePenaltyController,
              decoration: const InputDecoration(
                labelText: 'Late Payment Penalty Rate (% per day)',
                prefixIcon: Icon(Icons.schedule),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loan Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loanInterestController,
              decoration: const InputDecoration(
                labelText: 'Loan Interest Rate (%)',
                prefixIcon: Icon(Icons.percent),
                helperText: 'Interest charged on loans',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilitySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Visibility', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Public Group'),
              subtitle: const Text('Allow anyone to discover and join'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _loading ? null : _createGroup,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFF00A86B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _loading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Kora itsinda (Ishyura 2,000 RWF)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_walletBalance < 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amafaranga ntahagije. Shyiramo byibuze 2,000 RWF'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emeza kwishyura'),
        content: const Text('2,000 RWF izavamo muri wallet yawe. Komeza?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yego, ishyura')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final response = await _dio.post('/groups', data: {
        'name': _nameController.text,
        'description': _descController.text,
        'province': _province,
        'district': _district,
        'sector': _sector,
        'cell': _cell,
        'village': _village,
        'shareValue': double.parse(_shareValueController.text),
        'joinFee': double.parse(_joinFeeController.text),
        'penaltyAmount': double.parse(_penaltyController.text.isEmpty ? '0' : _penaltyController.text),
        'penaltyType': _penaltyType,
        'latePenaltyRate': double.parse(_latePenaltyController.text.isEmpty ? '0' : _latePenaltyController.text),
        'interestRate': 0,
        'loanInterestRate': double.parse(_loanInterestController.text.isEmpty ? '0' : _loanInterestController.text),
        'cycleType': 'MONTHLY',
        'contributionFrequency': _contributionFreq,
        'collectionDay': _collectionDay,
        'collectionTime': _collectionTime,
        'approvalThreshold': 2,
        'isPublic': _isPublic,
        'creatorId': widget.userId,
      });

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itsinda ryakozwe neza! 2,000 RWF yavanywe muri wallet.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e is DioException ? e.response?.data['error'] ?? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg ?? 'Ikosa ryabaye'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _shareValueController.dispose();
    _joinFeeController.dispose();
    _penaltyController.dispose();
    _latePenaltyController.dispose();
    _loanInterestController.dispose();
    super.dispose();
  }
}
