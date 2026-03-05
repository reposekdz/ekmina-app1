import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/investment_service.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
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
    _streamTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _investments.isNotEmpty) {
        setState(() {
          for (var inv in _investments) {
            if (inv['status'] == 'ACTIVE') {
              final amount = (inv['amount'] ?? 0).toDouble();
              final days = inv['durationDays'] ?? 30;
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
      final value = _currentValues[inv['id']] ?? (inv['amount'] ?? 0).toDouble();
      total += value;
      points.add(FlSpot(i.toDouble(), total));
    }
    
    setState(() => _graphData = points);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final investments = await _investmentService.getUserInvestments(widget.userId);
      final stats = await _investmentService.getInvestmentStats(widget.userId);
      final wallet = await _walletService.getWalletBalance(widget.userId);
      
      if (mounted) {
        setState(() {
          _investments = investments['investments'] ?? [];
          _stats = stats;
          _walletBalance = (wallet['balance'] ?? 0).toDouble();
          _isLoading = false;
          
          for (var inv in _investments) {
            if (inv['status'] == 'ACTIVE') {
              final amount = (inv['amount'] ?? 0).toDouble();
              final days = inv['durationDays'] ?? 30;
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            title: const Text('Ishoramari ryawe', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _loadData),
            ],
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              _buildLiveStatsCard().animate().fadeIn().scale(),
              const SizedBox(height: 24),
              if (_graphData.isNotEmpty) _buildGrowthGraph().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              if (_graphData.isNotEmpty) const SizedBox(height: 24),
              _buildQuickStats().animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),
              _buildInvestmentsList().animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateInvestmentScreen(userId: widget.userId))).then((_) => _loadData()),
        icon: const Icon(LucideIcons.plusCircle, color: Colors.white),
        label: const Text('Shyiramo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
      ).animate().scale(delay: 800.ms),
    );
  }

  Widget _buildLiveStatsCard() {
    final totalInvested = (_stats?['totalInvested'] ?? 0.0).toDouble();
    final currentTotal = _currentValues.values.fold(0.0, (sum, val) => sum + val);
    final displayTotal = currentTotal > 0 ? currentTotal : totalInvested;
    final liveProfit = displayTotal - totalInvested;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF00D68F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ishoramari Yose', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                      SizedBox(width: 6),
                      Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.formatCurrency(displayTotal),
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.trendingUp, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  '+${Formatters.formatCurrency(liveProfit > 0 ? liveProfit : 0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthGraph() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Uko Bikura', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(LucideIcons.lineChart, color: Colors.grey.shade300, size: 20),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _graphData,
                    isCurved: true,
                    color: AppTheme.primaryGreen,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true, 
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryGreen.withOpacity(0.2), AppTheme.primaryGreen.withOpacity(0.01)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeInvestments = _stats?['activeCount'] ?? 0;
    final totalReturns = (_stats?['totalReturns'] ?? 0.0).toDouble();
    final avgRate = (_stats?['avgRate'] ?? 0.0).toDouble();

    return Row(
      children: [
        Expanded(child: _buildStatCard('Bikora', '$activeInvestments', LucideIcons.briefcase, AppTheme.primaryBlue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Inyungu', Formatters.formatCompactNumber(totalReturns), LucideIcons.coins, AppTheme.primaryGreen)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Rate', '${(avgRate * 100).toStringAsFixed(1)}%', LucideIcons.percent, AppTheme.primaryYellow)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInvestmentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ishoramari ryawe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        if (_investments.isEmpty)
          _buildEmptyState()
        else
          ..._investments.map((inv) => _buildInvestmentCard(inv)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.pieChart, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Nta shoramari ufite', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(Map<String, dynamic> investment) {
    final amount = (investment['amount'] ?? 0).toDouble();
    final expectedReturn = (investment['expectedReturn'] ?? 0).toDouble();
    final maturityDate = DateTime.parse(investment['maturityDate']);
    final daysRemaining = maturityDate.difference(DateTime.now()).inDays.clamp(0, 999);
    final totalDays = investment['durationDays'] ?? 30;
    final progress = ((totalDays - daysRemaining) / totalDays).clamp(0.0, 1.0);
    final tier = _investmentService.getInvestmentTier(amount);
    final isActive = investment['status'] == 'ACTIVE';
    final currentValue = _currentValues[investment['id']] ?? amount;
    final currentProfit = currentValue - amount;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InvestmentDetailsScreen(investmentId: investment['id']))).then((_) => _loadData()),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [tier['color'], (tier['color'] as Color).withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(tier['badge'], style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tier['nameRw'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${(investment['interestRate'] * 100).toStringAsFixed(1)}% APY', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  _buildStatusChip(isActive),
                ],
              ),
              const SizedBox(height: 24),
              if (isActive) ...[
                _buildLiveGrowthSection(currentValue, currentProfit),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniInfo('Yashyizwe', Formatters.formatCurrency(amount)),
                  _buildMiniInfo('Inyungu yose', Formatters.formatCurrency(expectedReturn - amount), color: AppTheme.primaryGreen),
                ],
              ),
              const SizedBox(height: 20),
              _buildProgressSection(progress, daysRemaining),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isActive ? AppTheme.primaryGreen : Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'BIKORA' : 'BYARANGIYE', 
        style: TextStyle(color: isActive ? AppTheme.primaryGreen : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLiveGrowthSection(double currentValue, double currentProfit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Agaciro k\'ubu', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(Formatters.formatCurrency(currentValue), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(10)),
            child: Text('+${Formatters.formatCurrency(currentProfit)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildProgressSection(double progress, int daysRemaining) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(progress * 100).toInt()}% Byarangiye', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text('Hasigaye iminsi $daysRemaining', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
      ],
    );
  }
}
