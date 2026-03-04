import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../../../data/remote/api_client.dart';
import '../../../core/services/investment_service.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/utils/formatters.dart';
import 'create_investment_screen.dart';
import 'investment_details_screen.dart';

class InvestmentDashboardScreen extends ConsumerStatefulWidget {
  final String userId;
  const InvestmentDashboardScreen({super.key, required this.userId});

  @override
  ConsumerState<InvestmentDashboardScreen> createState() => _InvestmentDashboardScreenState();
}

class _InvestmentDashboardScreenState extends ConsumerState<InvestmentDashboardScreen> with TickerProviderStateMixin {
  late InvestmentService _investmentService;
  late WalletService _walletService;
  late AnimationController _pulseController;
  List<dynamic> _investments = [];
  Map<String, dynamic>? _stats;
  Map<String, double> _currentValues = {};
  double _walletBalance = 0;
  bool _isLoading = true;
  Timer? _streamTimer;
  List<FlSpot> _graphData = [];

  @override
  void initState() {
    super.initState();
    _investmentService = InvestmentService(ref.read(apiClientProvider));
    _walletService = WalletService(ref.read(apiClientProvider));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _loadData();
    _startRealTimeStreaming();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _streamTimer?.cancel();
    super.dispose();
  }

  void _startRealTimeStreaming() {
    _streamTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _investments.isNotEmpty) {
        setState(() {
          for (var inv in _investments) {
            if (inv['status'] == 'ACTIVE') {
              final amount = inv['amount'].toDouble();
              final days = inv['durationDays'];
              final startDate = DateTime.parse(inv['createdAt']);
              _currentValues[inv['id']] = _investmentService.calculateCurrentValue(amount: amount, durationDays: days, startDate: startDate);
            }
          }
        });
        _updateGraph();
      }
    });
  }

  void _updateGraph() {
    if (_investments.isEmpty) return;
    
    final points = <FlSpot>[];
    double total = 0;
    
    for (int i = 0; i < _investments.length && i < 7; i++) {
      final inv = _investments[i];
      final value = _currentValues[inv['id']] ?? inv['amount'].toDouble();
      total += value;
      points.add(FlSpot(i.toDouble(), total));
    }
    
    setState(() => _graphData = points);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final investments = await _investmentService.getUserInvestments(widget.userId);
      final stats = await _investmentService.getInvestmentStats(widget.userId);
      final wallet = await _walletService.getWalletBalance(widget.userId);
      
      if (mounted) {
        setState(() {
          _investments = investments['investments'] ?? [];
          _stats = stats;
          _walletBalance = wallet['balance'].toDouble();
          _isLoading = false;
          
          for (var inv in _investments) {
            if (inv['status'] == 'ACTIVE') {
              final amount = inv['amount'].toDouble();
              final days = inv['durationDays'];
              final startDate = DateTime.parse(inv['createdAt']);
              _currentValues[inv['id']] = _investmentService.calculateCurrentValue(amount: amount, durationDays: days, startDate: startDate);
            }
          }
        });
        _updateGraph();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ishoramari')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF00A86B))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ishoramari'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWalletCard(),
            const SizedBox(height: 16),
            _buildLiveStatsCard(),
            const SizedBox(height: 16),
            if (_graphData.isNotEmpty) _buildGrowthGraph(),
            if (_graphData.isNotEmpty) const SizedBox(height: 16),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildInvestmentsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateInvestmentScreen(userId: widget.userId))).then((_) => _loadData()),
        icon: const Icon(Icons.add_circle),
        label: const Text('Shyiramo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00A86B),
        elevation: 6,
      ),
    );
  }

  Widget _buildWalletCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wallet Yawe', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('${Formatters.formatCurrency(_walletBalance)} FRw', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatsCard() {
    final totalInvested = _stats?['totalInvested'] ?? 0.0;
    final currentTotal = _currentValues.values.fold(0.0, (sum, val) => sum + val);
    final liveProfit = currentTotal - totalInvested;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00C853)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF00A86B).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amafaranga Yawe', style: TextStyle(color: Colors.white70, fontSize: 16)),
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                      SizedBox(width: 6),
                      Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${Formatters.formatCurrency(currentTotal > 0 ? currentTotal : totalInvested)} FRw', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('+${Formatters.formatCurrency(liveProfit > 0 ? liveProfit : 0)} FRw', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthGraph() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.show_chart, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                const Text('Uko Bikura', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) => Text('${(value / 1000).toStringAsFixed(0)}K', style: const TextStyle(fontSize: 10)))),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _graphData,
                      isCurved: true,
                      color: const Color(0xFF00A86B),
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: const Color(0xFF00A86B).withOpacity(0.2)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeInvestments = _stats?['activeCount'] ?? 0;
    final totalReturns = _stats?['totalReturns'] ?? 0.0;
    final avgRate = _stats?['avgRate'] ?? 0.0;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Bikora', '$activeInvestments', Icons.account_balance_wallet, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Inyungu', '${Formatters.formatCurrency(totalReturns)} FRw', Icons.attach_money, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Igipimo', '${(avgRate * 100).toStringAsFixed(1)}%', Icons.percent, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Ishoramari Yawe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_investments.isNotEmpty) Text('${_investments.length}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        if (_investments.isEmpty)
          Card(
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Nta shoramari', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          )
        else
          ..._investments.map((inv) => _buildInvestmentCard(inv)),
      ],
    );
  }

  Widget _buildInvestmentCard(Map<String, dynamic> investment) {
    final amount = investment['amount'].toDouble();
    final expectedReturn = investment['expectedReturn'].toDouble();
    final maturityDate = DateTime.parse(investment['maturityDate']);
    final createdDate = DateTime.parse(investment['createdAt']);
    final daysRemaining = maturityDate.difference(DateTime.now()).inDays.clamp(0, 999);
    final totalDays = investment['durationDays'];
    final progress = ((totalDays - daysRemaining) / totalDays).clamp(0.0, 1.0);
    final tier = _investmentService.getInvestmentTier(amount);
    final isActive = investment['status'] == 'ACTIVE';
    final currentValue = _currentValues[investment['id']] ?? amount;
    final currentProfit = currentValue - amount;
    final perSecond = _investmentService.calculatePerSecondGrowth(amount, totalDays);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InvestmentDetailsScreen(investmentId: investment['id']))).then((_) => _loadData()),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [tier['color'], tier['color'].withOpacity(0.7)]), borderRadius: BorderRadius.circular(12)),
                    child: Text(tier['badge'], style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tier['nameRw'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${(investment['interestRate'] * 100).toStringAsFixed(2)}% ku mwaka', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: isActive ? const Color(0xFF00A86B).withOpacity(0.15) : Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(isActive ? 'BIKORA' : 'BYARANGIYE', style: TextStyle(color: isActive ? const Color(0xFF00A86B) : Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isActive) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green[50]!, Colors.green[100]!]), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ubu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          FadeTransition(
                            opacity: _pulseController,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                              child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${Formatters.formatCurrency(currentValue)} FRw', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          Text('+${Formatters.formatCurrency(currentProfit)} FRw', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${Formatters.formatCurrency(perSecond)} FRw/isegonda', style: TextStyle(fontSize: 11, color: Colors.green[700])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Yashyizwe', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('${Formatters.formatCurrency(amount)} FRw', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Uzahabwa', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('${Formatters.formatCurrency(expectedReturn)} FRw', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tier['color'])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('$daysRemaining iminsi', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], color: tier['color'], minHeight: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
