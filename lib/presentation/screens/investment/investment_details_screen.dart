import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/investment_service.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/pin_input_widget.dart';

class InvestmentDetailsScreen extends ConsumerStatefulWidget {
  final String investmentId;
  const InvestmentDetailsScreen({super.key, required this.investmentId});

  @override
  ConsumerState<InvestmentDetailsScreen> createState() => _InvestmentDetailsScreenState();
}

class _InvestmentDetailsScreenState extends ConsumerState<InvestmentDetailsScreen> with TickerProviderStateMixin {
  late InvestmentService _investmentService;
  late AnimationController _pulseController;
  late AnimationController _growthController;
  Map<String, dynamic>? _investment;
  bool _isLoading = true;
  double _currentValue = 0;
  Timer? _streamTimer;

  @override
  void initState() {
    super.initState();
    _investmentService = InvestmentService(ref.read(apiClientProvider));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _growthController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadInvestment();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _growthController.dispose();
    _streamTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInvestment() async {
    try {
      final data = await _investmentService.getInvestmentDetails(widget.investmentId);
      if (mounted) {
        setState(() {
          _investment = data['investment'];
          _isLoading = false;
        });
        _startRealTimeStreaming();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startRealTimeStreaming() {
    if (_investment == null || _investment!['status'] != 'ACTIVE') return;

    _streamTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _investment != null) {
        final amount = (_investment!['amount'] as num).toDouble();
        final days = (_investment!['durationDays'] as num).toInt();
        final startDate = DateTime.parse(_investment!['createdAt']);
        
        setState(() {
          _currentValue = _investmentService.calculateCurrentValue(
            amount: amount,
            durationDays: days,
            startDate: startDate,
          );
        });
        
        _growthController.forward(from: 0);
      }
    });
  }

  Future<void> _withdrawInvestment(bool isEarly) async {
    final pin = await PINInputDialog.show(context, title: 'Emeza', subtitle: 'Shyiramo PIN yawe');
    if (pin == null) return;

    try {
      await _investmentService.withdrawInvestment(investmentId: widget.investmentId, isEarly: isEarly);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Amafaranga yakuweho neza!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ikosa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ibisobanuro')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF00A86B))),
      );
    }
    
    if (_investment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ibisobanuro')),
        body: const Center(child: Text('Nta makuru')),
      );
    }

    final amount = (_investment!['amount'] as num).toDouble();
    final expectedReturn = (_investment!['expectedReturn'] as num).toDouble();
    final profit = expectedReturn - amount;
    final maturityDate = DateTime.parse(_investment!['maturityDate']);
    final createdDate = DateTime.parse(_investment!['createdAt']);
    final daysRemaining = maturityDate.difference(DateTime.now()).inDays.clamp(0, 999);
    final daysInvested = DateTime.now().difference(createdDate).inDays;
    final totalDays = (_investment!['durationDays'] as num).toInt();
    final isMatured = daysRemaining <= 0;
    final isActive = _investment!['status'] == 'ACTIVE';
    final tier = _investmentService.getInvestmentTier(amount);
    final perSecond = _investmentService.calculatePerSecondGrowth(amount, totalDays);
    final dailyReturn = _investmentService.calculateDailyReturn(amount, totalDays);
    
    final displayValue = isActive && _currentValue > 0 ? _currentValue : (isMatured ? expectedReturn : amount);
    final currentProfit = displayValue - amount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ibisobanuro Byimbitse'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareInvestment(amount, currentProfit, tier['nameRw']),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTierHeader(tier),
          const SizedBox(height: 20),
          if (isActive) _buildLiveValueCard(displayValue, currentProfit, perSecond),
          if (isActive) const SizedBox(height: 20),
          _buildExpectedReturnCard(expectedReturn, profit),
          const SizedBox(height: 20),
          _buildGrowthStatsCard(perSecond, dailyReturn, profit, totalDays),
          const SizedBox(height: 20),
          _buildProgressCard(daysInvested, daysRemaining, totalDays, tier),
          const SizedBox(height: 20),
          _buildDetailsCard(amount, createdDate, maturityDate, tier),
          const SizedBox(height: 20),
          _buildPlatformProfitCard(amount, totalDays),
          const SizedBox(height: 32),
          _buildActionButtons(isMatured, isActive, amount, daysInvested, totalDays),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTierHeader(Map<String, dynamic> tier) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tier['color'], tier['color'].withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: tier['color'].withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Text(tier['badge'], style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier['nameRw'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Tier: ${tier['name']}', style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text('${(_investment!['interestRate'] * 100).toStringAsFixed(1)}% APY', style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveValueCard(double currentValue, double currentProfit, double perSecond) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00A86B).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AGACIRO K\'ISHORAMARI', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF00A86B).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.sensors, color: Color(0xFF00A86B), size: 12),
                      SizedBox(width: 4),
                      Text('LIVE', style: TextStyle(color: Color(0xFF00A86B), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            child: Text(Formatters.formatCurrency(currentValue), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF00A86B), size: 20),
              const SizedBox(width: 8),
              Text('+${Formatters.formatCurrency(currentProfit)}', style: const TextStyle(color: Color(0xFF00A86B), fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Text('Inyungu: ${Formatters.formatCurrency(perSecond)} / isegonda', style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedReturnCard(double expectedReturn, double profit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.account_balance_wallet, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UZAHABWA BYARANGIYE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(Formatters.formatCurrency(expectedReturn), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004BA0))),
              ],
            ),
          ),
          Text('+${Formatters.formatCurrency(profit)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildGrowthStatsCard(double perSecond, double dailyReturn, double profit, int totalDays) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UKO ISHORAMARI RYAMERA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 20),
            _buildStatRow('Ku munsi', '+${Formatters.formatCurrency(dailyReturn)}', Icons.calendar_today, Colors.blue),
            _buildStatRow('Ku cyumweru', '+${Formatters.formatCurrency(dailyReturn * 7)}', Icons.date_range, Colors.orange),
            _buildStatRow('Ku kwezi', '+${Formatters.formatCurrency(dailyReturn * 30)}', Icons.calendar_month, Colors.purple),
            _buildStatRow('Inyungu yose', '+${Formatters.formatCurrency(profit)}', Icons.auto_graph, const Color(0xFF00A86B)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int daysInvested, int daysRemaining, int totalDays, Map<String, dynamic> tier) {
    final progress = (daysInvested / totalDays).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IGIHENGO CY\'ISHORAMARI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('${(progress * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tier['color'])),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[100],
              color: tier['color'],
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildProgressStat('Byarangiye', '$daysInvested iminsi', Icons.history, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildProgressStat('Bisigaye', '$daysRemaining iminsi', Icons.timer_outlined, Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(double amount, DateTime createdDate, DateTime maturityDate, Map<String, dynamic> tier) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IBISOBANURO BY\'ISHORAMARI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 20),
            _buildDetailRow('Igishoro', Formatters.formatCurrency(amount), Icons.payments_outlined),
            _buildDetailRow('Itariki Cyatangiriye', Formatters.formatDate(createdDate), Icons.calendar_month_outlined),
            _buildDetailRow('Itariki Kizarangiriraho', Formatters.formatDate(maturityDate), Icons.event_available_outlined),
            _buildDetailRow('Igihe Cyose', '${_investment!['durationDays']} iminsi', Icons.update),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPlatformProfitCard(double amount, int days) {
    final platformProfit = _investmentService.calculatePlatformProfit(amount, days);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9D7FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF7F56D9).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.security, color: Color(0xFF7F56D9), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('E-KIMINA PROFIT PROTECTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7F56D9))),
            ],
          ),
          const SizedBox(height: 20),
          _buildProfitRow('Inyungu yawe (Guaranteed)', Formatters.formatCurrency(platformProfit['userReturn']!), Colors.green),
          _buildProfitRow('E-Kimina Ecosystem Yield', Formatters.formatCurrency(platformProfit['lendingReturn']!), Colors.blue),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Platform Sustainability Fee', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6941C6))),
              Text(Formatters.formatCurrency(platformProfit['platformProfit']!), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6941C6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isMatured, bool isActive, double amount, int daysInvested, int totalDays) {
    if (isMatured) {
      return Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: const Color(0xFF00A86B).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _withdrawInvestment(false),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('KURAMO AMAFARANGA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A86B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      );
    }

    if (isActive) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: OutlinedButton.icon(
              onPressed: () => _showEarlyWithdrawalDialog(amount, daysInvested, totalDays),
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              label: const Text('KURAMO MBERE Y\'IGIHE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withOpacity(0.1))),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Uzahabwa igihano niba ukuye amafaranga ishoramari ritararangira.', style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showEarlyWithdrawalDialog(double amount, int daysInvested, int totalDays) {
    final penalty = _investmentService.calculateEarlyWithdrawalPenalty(amount, daysInvested, totalDays);
    final amountAfterPenalty = amount - penalty;
    final remainingDays = totalDays - daysInvested;
    final remainingRatio = remainingDays / totalDays;
    final penaltyPercent = remainingRatio > 0.75 ? 25 : remainingRatio > 0.50 ? 18 : remainingRatio > 0.25 ? 12 : 6;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Kuramo Mbere y\'Igihe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded, color: Colors.orange, size: 32),
            ),
            const SizedBox(height: 24),
            const Text('Uremeza ko ukuye amafaranga?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Iri shoramari risigaje iminsi $remainingDays.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            _buildDialogStat('Igihano ($penaltyPercent%)', Formatters.formatCurrency(penalty), Colors.red),
            const Divider(height: 32),
            _buildDialogStat('Ayasigaye uzakira', Formatters.formatCurrency(amountAfterPenalty), Colors.green),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HAGARIKA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _withdrawInvestment(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('KOMEZA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogStat(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      ],
    );
  }

  void _shareInvestment(double amount, double profit, String tierName) {
    final text = 'Namaze gushyira ${Formatters.formatCurrency(amount)} mu ishoramari rya E-Kimina ($tierName)! Inyungu yanjye ubu ni ${Formatters.formatCurrency(profit)}. Bika, guza, kandi utere imbere nawe: https://ekimina.rw';
    Share.share(text);
  }
}
