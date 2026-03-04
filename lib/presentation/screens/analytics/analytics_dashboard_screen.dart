import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _analyticsData;
  bool _loading = true;
  String _selectedPeriod = 'Ukwezi';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final storage = SecureStorageService();
      final userId = await storage.getUserId();
      if (userId == null) return;

      final api = ref.read(apiClientProvider);
      // Assuming endpoint exists or calculating from existing data
      final walletData = await api.getWallet(userId);
      final groupsData = await api.getGroups(userId);
      final transactionsData = await api.getTransactions(userId: userId);

      if (mounted) {
        setState(() {
          _analyticsData = {
            'wallet': walletData['wallet'],
            'groups': groupsData['groups'],
            'transactions': transactionsData['transactions'],
          };
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imibare n\'imikorere', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Rusange'),
            Tab(text: 'Amatsinda'),
            Tab(text: 'Inguzanyo'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAnalytics),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildGroupsTab(),
                _buildLoansTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 20),
            _buildMainStats(),
            const SizedBox(height: 32),
            const Text('Iterambere ry\'imigabane', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildLineChart(),
            const SizedBox(height: 32),
            const Text('Uko ukoresha amafaranga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDistributionChart(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: ['Icyumweru', 'Ukwezi', 'Umwaka'].map((p) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = p),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _selectedPeriod == p ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: _selectedPeriod == p ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
              ),
              child: Text(p, textAlign: TextAlign.center, style: TextStyle(fontWeight: _selectedPeriod == p ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMainStats() {
    final wallet = _analyticsData?['wallet'];
    return Row(
      children: [
        Expanded(child: _buildStatTile('Imigabane', Formatters.formatCompactNumber(wallet?['totalShares'] ?? 0), AppTheme.primaryGreen, Icons.savings_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatTile('Inguzanyo', Formatters.formatCompactNumber(wallet?['totalLoans'] ?? 0), Colors.orange, Icons.request_quote_outlined)),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(0, 20, 20, 0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'][v.toInt() % 6], style: const TextStyle(fontSize: 10, color: Colors.grey))))),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [FlSpot(0, 1), FlSpot(1, 1.5), FlSpot(2, 1.2), FlSpot(3, 2.5), FlSpot(4, 2), FlSpot(5, 3)],
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

  Widget _buildDistributionChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: 60, color: AppTheme.primaryGreen, radius: 40, showTitle: false),
                  PieChartSectionData(value: 25, color: AppTheme.accentBlue, radius: 40, showTitle: false),
                  PieChartSectionData(value: 15, color: Colors.orange, radius: 40, showTitle: false),
                ],
                centerSpaceRadius: 30,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Imisanzu', '60%', AppTheme.primaryGreen),
                _buildLegendItem('Inguzanyo', '25%', AppTheme.accentBlue),
                _buildLegendItem('Ibindi', '15%', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    final groups = _analyticsData?['groups'] as List? ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final g = groups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(backgroundColor: AppTheme.primaryGreen.withOpacity(0.1), child: const Icon(Icons.group, color: AppTheme.primaryGreen)),
            title: Text(g['name'] ?? 'Itsinda', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Abanyamuryango: ${g['memberCount'] ?? 0}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatters.formatCompactNumber(g['escrowBalance'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                const Text('Escrow', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoansTab() {
    return const Center(child: Text('Imibare y\'inguzanyo iri gupangwa...'));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
