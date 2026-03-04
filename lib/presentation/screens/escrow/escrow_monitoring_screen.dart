import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class EscrowMonitoringScreen extends StatefulWidget {
  final String groupId;
  const EscrowMonitoringScreen({super.key, required this.groupId});

  @override
  State<EscrowMonitoringScreen> createState() => _EscrowMonitoringScreenState();
}

class _EscrowMonitoringScreenState extends State<EscrowMonitoringScreen> {
  final double _escrowBalance = 5450000;
  final double _totalDeposits = 8200000;
  final double _totalWithdrawals = 2750000;
  final double _pendingTransactions = 150000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escrow Monitoring'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportReport),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildSectionTitle('Imikorere y\'amafaranga'),
            const SizedBox(height: 16),
            _buildFlowChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('Ibyakozwe vuba'),
            const SizedBox(height: 16),
            _buildRecentTransactions(),
            const SizedBox(height: 24),
            _buildSectionTitle('Umutekano'),
            const SizedBox(height: 16),
            _buildSecurityStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00C853)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Escrow Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Secure', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${NumberFormat('#,###').format(_escrowBalance)} RWF',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildBalanceItem('Byinjiye', _totalDeposits, Icons.arrow_downward)),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              Expanded(child: _buildBalanceItem('Byasohotse', _totalWithdrawals, Icons.arrow_upward)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat('#,###').format(amount)} RWF',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Bitegereje', _pendingTransactions, Icons.pending, Colors.orange),
        _buildStatCard('Ibyakozwe', 156, Icons.receipt_long, Colors.blue),
        _buildStatCard('Abanyamuryango', 24, Icons.people, Colors.purple),
        _buildStatCard('Inguzanyo', 8, Icons.request_quote, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String label, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value is double ? '${NumberFormat('#,###').format(value)} RWF' : value.toString(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(1, 4),
                FlSpot(2, 3.5),
                FlSpot(3, 5),
                FlSpot(4, 4.5),
                FlSpot(5, 5.5),
              ],
              isCurved: true,
              color: const Color(0xFF00A86B),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00A86B).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactions = [
      {'type': 'deposit', 'desc': 'Kwishyura - Jean Uwimana', 'amount': 50000, 'time': '2 saa zashize'},
      {'type': 'withdrawal', 'desc': 'Inguzanyo - Marie Mukamana', 'amount': -300000, 'time': '5 saa zashize'},
      {'type': 'deposit', 'desc': 'Kwishyura - Paul Habimana', 'amount': 50000, 'time': 'Ejo'},
    ];

    return Column(
      children: transactions.map((tx) {
        final isDeposit = tx['type'] == 'deposit';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDeposit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              child: Icon(
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isDeposit ? Colors.green : Colors.red,
              ),
            ),
            title: Text(tx['desc'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(tx['time'] as String),
            trailing: Text(
              '${isDeposit ? '+' : ''}${NumberFormat('#,###').format(tx['amount'])} RWF',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDeposit ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSecurityStatus() {
    final features = [
      {'icon': Icons.lock, 'title': 'Multi-signature', 'status': 'Active', 'color': Colors.green},
      {'icon': Icons.verified_user, 'title': 'Bank Integration', 'status': 'Connected', 'color': Colors.green},
      {'icon': Icons.security, 'title': 'Encryption', 'status': 'Enabled', 'color': Colors.green},
      {'icon': Icons.history, 'title': 'Audit Log', 'status': 'Recording', 'color': Colors.green},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: features.map((feature) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: (feature['color'] as Color).withOpacity(0.1),
                child: Icon(feature['icon'] as IconData, color: feature['color'] as Color),
              ),
              title: Text(feature['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (feature['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  feature['status'] as String,
                  style: TextStyle(color: feature['color'] as Color, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  void _refreshData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Amakuru yavuguruwe!')),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Raporo yoherejwe kuri email yawe')),
    );
  }
}
