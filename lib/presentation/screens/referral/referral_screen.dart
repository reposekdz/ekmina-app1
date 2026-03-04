import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final String _referralCode = 'EKIMINA2024';
  final int _referralCount = 12;
  final double _referralEarnings = 60000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tuma inshuti')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReferralCard(),
            const SizedBox(height: 24),
            _buildStatsCards(),
            const SizedBox(height: 24),
            _buildHowItWorks(),
            const SizedBox(height: 24),
            _buildReferralHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00C853)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Code yawe', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _referralCode,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: const Text('Koporora', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareCode,
                  icon: const Icon(Icons.share),
                  label: const Text('Sangiza'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00A86B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _showQRCode,
            icon: const Icon(Icons.qr_code, color: Colors.white),
            label: const Text('Erekana QR Code', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Inshuti', _referralCount.toString(), Icons.people, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Inyungu', '${_referralEarnings.toStringAsFixed(0)} RWF', Icons.monetization_on, Colors.green),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bigenda bite?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStep(1, 'Sangiza code yawe', 'Sangiza code yawe n\'inshuti zawe'),
            _buildStep(2, 'Ziyandikishe', 'Inshuti zawe zikoreshe code yawe'),
            _buildStep(3, 'Bongeramo', 'Bongeramo 5,000 RWF kuri buri nshuti'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF00A86B),
            child: Text(number.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralHistory() {
    final referrals = [
      {'name': 'Jean Uwimana', 'date': '15/03/2024', 'status': 'active', 'reward': '5,000 RWF'},
      {'name': 'Marie Mukamana', 'date': '10/03/2024', 'status': 'active', 'reward': '5,000 RWF'},
      {'name': 'Paul Habimana', 'date': '05/03/2024', 'status': 'pending', 'reward': '0 RWF'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amateka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...referrals.map((ref) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ref['status'] == 'active' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              child: Icon(
                ref['status'] == 'active' ? Icons.check_circle : Icons.pending,
                color: ref['status'] == 'active' ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(ref['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(ref['date']!),
            trailing: Text(ref['reward']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A86B))),
          ),
        )),
      ],
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code yakoporoye!')),
    );
  }

  void _shareCode() {
    Share.share(
      'Injira kuri E-Kimina ukoreshe code yanjye: $_referralCode\n\nBongeramo 5,000 RWF!',
      subject: 'Injira kuri E-Kimina',
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scan QR Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              QrImageView(data: 'REFERRAL:$_referralCode', version: QrVersions.auto, size: 250),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Funga')),
            ],
          ),
        ),
      ),
    );
  }
}
