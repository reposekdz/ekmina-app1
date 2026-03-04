import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../../../data/remote/api_client.dart';
import '../../../core/services/investment_service.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/pin_input_widget.dart';

class CreateInvestmentScreen extends ConsumerStatefulWidget {
  final String userId;
  const CreateInvestmentScreen({super.key, required this.userId});

  @override
  ConsumerState<CreateInvestmentScreen> createState() => _CreateInvestmentScreenState();
}

class _CreateInvestmentScreenState extends ConsumerState<CreateInvestmentScreen> with TickerProviderStateMixin {
  late InvestmentService _investmentService;
  late WalletService _walletService;
  late AnimationController _animController;
  late AnimationController _graphController;
  final _amountController = TextEditingController();
  int _durationDays = 30;
  bool _isLoading = false;
  bool _useWallet = true;
  Timer? _previewTimer;
  double _simulatedGrowth = 0;
  double _walletBalance = 0;
  List<FlSpot> _graphData = [];

  @override
  void initState() {
    super.initState();
    _investmentService = InvestmentService(ref.read(apiClientProvider));
    _walletService = WalletService(ref.read(apiClientProvider));
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _graphController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animController.forward();
    _loadWalletBalance();
    _startPreviewSimulation();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animController.dispose();
    _graphController.dispose();
    _previewTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWalletBalance() async {
    try {
      final data = await _walletService.getWalletBalance(widget.userId);
      if (mounted) setState(() => _walletBalance = data['balance'].toDouble());
    } catch (e) {}
  }

  void _startPreviewSimulation() {
    _previewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final amount = double.tryParse(_amountController.text) ?? 0;
        if (amount >= 200) {
          final perSecond = _investmentService.calculatePerSecondGrowth(amount, _durationDays);
          setState(() => _simulatedGrowth += perSecond);
        }
      }
    });
  }

  void _updateGraph() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 200) {
      setState(() => _graphData = []);
      return;
    }

    final points = <FlSpot>[];
    final dailyReturn = _investmentService.calculateDailyReturn(amount, _durationDays);
    
    for (int i = 0; i <= _durationDays; i += (_durationDays / 10).ceil()) {
      final value = amount + (dailyReturn * i);
      points.add(FlSpot(i.toDouble(), value));
    }
    
    setState(() => _graphData = points);
    _graphController.forward(from: 0);
  }

  Future<void> _createInvestment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount < 200) {
      _showError('Amafaranga ntarengwa ni 200 FRw');
      return;
    }

    if (_durationDays < 10) {
      _showError('Igihe ntarengwa ni iminsi 10');
      return;
    }

    if (_useWallet && amount > _walletBalance) {
      _showError('Wallet yawe ntabwo ifite amafaranga ahagije');
      return;
    }

    final pin = await PINInputDialog.show(context, title: 'Emeza', subtitle: 'Shyiramo PIN yawe');
    if (pin == null) return;

    setState(() => _isLoading = true);
    try {
      if (_useWallet) {
        await _walletService.transferToInvestment(userId: widget.userId, amount: amount, pin: pin);
      }
      
      await _investmentService.createInvestment(amount: amount, durationDays: _durationDays, pin: pin);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ishoramari ryashyizweho neza!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showError('Ikosa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ $message'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final tier = amount >= 200 ? _investmentService.getInvestmentTier(amount) : null;
    final rate = amount >= 200 ? _investmentService.calculateInterestRate(amount, _durationDays) : 0;
    final expectedReturn = amount >= 200 ? _investmentService.calculateExpectedReturn(amount: amount, durationDays: _durationDays) : 0;
    final profit = expectedReturn - amount;
    final dailyReturn = amount >= 200 ? _investmentService.calculateDailyReturn(amount, _durationDays) : 0;
    final perSecond = amount >= 200 ? _investmentService.calculatePerSecondGrowth(amount, _durationDays) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shyiramo Amafaranga'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: _showInfoDialog),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWalletCard(),
          const SizedBox(height: 16),
          if (tier != null) _buildTierCard(tier, rate),
          const SizedBox(height: 20),
          _buildAmountInput(),
          const SizedBox(height: 20),
          _buildDurationSection(),
          const SizedBox(height: 20),
          if (amount >= 200) ...[
            _buildGrowthGraph(),
            const SizedBox(height: 16),
            _buildGrowthPreview(perSecond, dailyReturn),
            const SizedBox(height: 16),
            _buildStatsGrid(profit, rate, dailyReturn),
            const SizedBox(height: 16),
            _buildSummaryCard(amount, expectedReturn, profit, rate),
            const SizedBox(height: 20),
          ],
          _buildActionButton(),
        ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet Yawe', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('E-Kimina Wallet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadWalletBalance,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('${Formatters.formatCurrency(_walletBalance)} FRw', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _useWallet,
                  onChanged: (v) => setState(() => _useWallet = v!),
                  fillColor: MaterialStateProperty.all(Colors.white),
                  checkColor: const Color(0xFF1E88E5),
                ),
                const Text('Koresha wallet', style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier, double rate) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [tier['color'], tier['color'].withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: tier['color'].withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tier['badge'], style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Icon(tier['icon'], size: 40, color: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            Text(tier['nameRw'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(25)),
              child: Text('${(rate * 100).toStringAsFixed(2)}% ku mwaka', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 8),
            Text(tier['range'], style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF00A86B).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_wallet, color: Color(0xFF00A86B)),
                ),
                const SizedBox(width: 12),
                const Text('Amafaranga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '200',
                suffixText: 'FRw',
                suffixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A86B), width: 2)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (_) {
                setState(() => _simulatedGrowth = 0);
                _updateGraph();
              },
            ),
            const SizedBox(height: 8),
            const Text('Ntarengwa: 200 FRw | Nta mpera', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection() {
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.schedule, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text('Igihe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _investmentService.durationOptions.map((option) {
                final isSelected = _durationDays == option['days'];
                return ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(option['label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (option['bonus'] > 0) Text('+${option['bonus']}%', style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.green)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _durationDays = option['days']);
                    _updateGraph();
                  },
                  selectedColor: const Color(0xFF00A86B),
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthGraph() {
    if (_graphData.isEmpty) return const SizedBox.shrink();

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
                const Text('Uko Azamera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: FadeTransition(
                opacity: _graphController,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (_graphData.last.y - _graphData.first.y) / 5),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60, getTitlesWidget: (value, meta) => Text('${(value / 1000).toStringAsFixed(0)}K', style: const TextStyle(fontSize: 10)))),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: _durationDays / 5, getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10)))),
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
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: const Color(0xFF00A86B).withOpacity(0.2)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthPreview(double perSecond, double dailyReturn) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00C853)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text('Uko Amafaranga Azamera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text('Ku isegonda', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('+${Formatters.formatCurrency(perSecond)} FRw', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text('Ku munsi', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('+${Formatters.formatCurrency(dailyReturn)} FRw', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Wongereye: ${Formatters.formatCurrency(_simulatedGrowth)} FRw', style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(double profit, double rate, double dailyReturn) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Inyungu Yawe', '${Formatters.formatCurrency(profit)} FRw', Icons.attach_money, Colors.green),
        _buildStatCard('Igipimo', '${(rate * 100).toStringAsFixed(2)}%', Icons.percent, Colors.blue),
        _buildStatCard('Iminsi', '$_durationDays', Icons.calendar_today, Colors.orange),
        _buildStatCard('Ku munsi', '${Formatters.formatCurrency(dailyReturn)} FRw', Icons.today, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]), borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double amount, double expectedReturn, double profit, double rate) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.grey[50]!]), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF00A86B).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.summarize, color: Color(0xFF00A86B)),
                ),
                const SizedBox(width: 12),
                const Text('Ibisobanuro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            _buildSummaryRow('Yashyizwe', '${Formatters.formatCurrency(amount)} FRw', Icons.input),
            _buildSummaryRow('Igipimo', '${(rate * 100).toStringAsFixed(2)}%', Icons.trending_up),
            _buildSummaryRow('Igihe', '$_durationDays iminsi', Icons.schedule),
            _buildSummaryRow('Inyungu', '+${Formatters.formatCurrency(profit)} FRw', Icons.add_circle, color: Colors.green),
            const Divider(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00C853)]), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Uzahabwa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Text('${Formatters.formatCurrency(expectedReturn)} FRw', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final isValid = amount >= 200 && _durationDays >= 10;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading || !isValid ? null : _createInvestment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A86B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 24),
                  SizedBox(width: 12),
                  Text('Emeza Ishoramari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Color(0xFF00A86B)),
            SizedBox(width: 8),
            Text('Amakuru'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✅ Ntarengwa: 200 FRw', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('✅ Nta mpera ku mafaranga'),
              SizedBox(height: 8),
              Text('✅ Igihe: 10-365 iminsi'),
              SizedBox(height: 8),
              Text('✅ Igipimo: 8-45% ku mwaka'),
              SizedBox(height: 8),
              Text('✅ Amafaranga azamera buri isegonda'),
              SizedBox(height: 8),
              Text('✅ Umutekano ukomeye (Escrow)'),
              SizedBox(height: 8),
              Text('✅ Koresha wallet cyangwa MTN/Airtel'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Siga')),
        ],
      ),
    );
  }
}
