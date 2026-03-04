import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final String groupId;
  const ReportsScreen({super.key, required this.groupId});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _reportData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getReports(widget.groupId);
      if (mounted) {
        setState(() {
          _reportData = response;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Raporo n\'Imibare')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporo n\'Imibare', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports)],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Rusange'),
            Tab(text: 'Imari'),
            Tab(text: 'Abanyamuryango'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildFinancialTab(),
          _buildMembersTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _reportData?['stats'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(stats),
          const SizedBox(height: 24),
          const Text('Imyitwarire y\'imari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSimpleLineChart(),
          const SizedBox(height: 24),
          _buildStatsGrid(stats),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('Amafaranga yose ari muri Escrow', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(Formatters.formatCurrency((stats['escrowBalance'] ?? 0).toDouble()),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Divider(height: 32, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Abanyamuryango', '${stats['memberCount'] ?? 0}'),
              _buildMiniStat('Inguzanyo', '${stats['activeLoans'] ?? 0}'),
              _buildMiniStat('Imigabane', Formatters.formatCompactNumber(stats['totalShares'] ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildSimpleLineChart() {
    return Container(
      height: 180,
      padding: const EdgeInsets.only(top: 20, right: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [FlSpot(0, 1), FlSpot(1, 2), FlSpot(2, 1.5), FlSpot(3, 3), FlSpot(4, 2.5), FlSpot(5, 4)],
              isCurved: true,
              color: AppTheme.primaryGreen,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppTheme.primaryGreen.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatBox('Imisanzu yishyuwe', '${(stats['contributionRate'] ?? 0).toStringAsFixed(1)}%', Colors.blue, Icons.check_circle_outline),
        _buildStatBox('Ibihano', Formatters.formatCompactNumber(stats['totalPenalties'] ?? 0), Colors.redAccent, Icons.warning_amber_rounded),
        _buildStatBox('Inyungu yabonetse', Formatters.formatCompactNumber(stats['totalInterest'] ?? 0), Colors.orange, Icons.trending_up),
        _buildStatBox('Inguzanyo zatanzwe', Formatters.formatCompactNumber(stats['totalLoansGiven'] ?? 0), Colors.purple, Icons.request_quote_outlined),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    final financial = _reportData?['financial'] ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFinancialCard('Amafaranga Yinjiye', [
          _buildFinRow('Imisanzu', financial['contributions'] ?? 0, Colors.green),
          _buildFinRow('Amafaranga yo kwinjira', financial['joinFees'] ?? 0, Colors.blue),
          _buildFinRow('Inyungu ku nguzanyo', financial['loanInterest'] ?? 0, Colors.orange),
          _buildFinRow('Ibihano byakusanyijwe', financial['penalties'] ?? 0, Colors.redAccent),
        ]),
        const SizedBox(height: 16),
        _buildFinancialCard('Amafaranga Yasohotse', [
          _buildFinRow('Inguzanyo zatanzwe', financial['loansGiven'] ?? 0, Colors.purple),
          _buildFinRow('Inyungu zagabanijwe', financial['dividendsPaid'] ?? 0, Colors.teal),
          _buildFinRow('Ibindi bisohoka', financial['otherExpenses'] ?? 0, Colors.grey),
        ]),
      ],
    );
  }

  Widget _buildFinancialCard(String title, List<Widget> rows) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildFinRow(String label, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
          Text(Formatters.formatCurrency(value.toDouble()), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    final members = _reportData?['members'] as List? ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final m = members[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            leading: CircleAvatar(child: Text(m['user']['name']?[0] ?? 'U')),
            title: Text(m['user']['name'] ?? 'Umunyamuryango', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Imigabane: ${Formatters.formatCurrency(m['totalShares']?.toDouble() ?? 0)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(m['role'] ?? 'MEMBER', style: const TextStyle(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                Text('${(m['attendanceRate'] ?? 0).toStringAsFixed(0)}% bitabiriye', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
