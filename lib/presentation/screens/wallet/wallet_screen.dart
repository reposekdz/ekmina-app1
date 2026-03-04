import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _balance = 0;
  List<dynamic> _transactions = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final storage = SecureStorageService();
      _userId = await storage.getUserId();
      if (_userId == null) return;

      final api = ref.read(apiClientProvider);
      final walletData = await api.getWallet(_userId!);
      final transactionsData = await api.getTransactions(userId: _userId);

      if (mounted) {
        final txList = transactionsData['transactions'] as List? ?? [];
        final deposits = txList.where((t) => t['type'] == 'DEPOSIT' || t['type'] == 'CONTRIBUTION').fold(0.0, (sum, t) => sum + (t['amount'] ?? 0));
        final withdrawals = txList.where((t) => t['type'] == 'WITHDRAWAL' || t['type'] == 'LOAN_REPAYMENT').fold(0.0, (sum, t) => sum + (t['amount'] ?? 0));

        setState(() {
          _balance = (walletData['wallet']?['balance'] ?? 0).toDouble();
          _transactions = txList;
          _stats = {
            'totalDeposits': deposits,
            'totalWithdrawals': withdrawals,
            'transactionCount': txList.length,
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ijakanshyi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ijakanshyi ryanjye', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Ibanze'),
            Tab(text: 'Ibikorwa'),
            Tab(text: 'Imibare'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTransactionsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Text('Amafaranga ufite yose', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(Formatters.formatCurrency(_balance),
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallStat('Inyungu', '8,450 RWF', Icons.trending_up),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildSmallStat('Imigabane', Formatters.formatCompactNumber(_stats?['totalDeposits'] ?? 0), Icons.pie_chart),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickAction('Eshyuza', Icons.add_circle, AppTheme.primaryGreen, () => _showDepositDialog()),
        _buildQuickAction('Kuramo', Icons.remove_circle, Colors.orange, () => _showWithdrawDialog()),
        _buildQuickAction('Ohereza', Icons.send, AppTheme.accentBlue, () => context.push('/wallet/send')),
        _buildQuickAction('Amateka', Icons.history, Colors.blueGrey, () => _tabController.animateTo(1)),
      ],
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Ibyakozwe vuba', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => _tabController.animateTo(1), child: const Text('Byose')),
          ],
        ),
        const SizedBox(height: 8),
        if (_transactions.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Nta bikorwa bihari')))
        else
          ..._transactions.take(3).map((tx) => _buildTransactionItem(tx)),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('Nta bikorwa urakora'));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) => _buildTransactionItem(_transactions[index]),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    final isInflow = tx['type'] == 'DEPOSIT' || tx['type'] == 'CONTRIBUTION' || tx['type'] == 'LOAN_DISBURSEMENT';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isInflow ? AppTheme.successGreen.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(isInflow ? Icons.arrow_downward : Icons.arrow_upward,
            color: isInflow ? AppTheme.successGreen : Colors.redAccent, size: 20),
        ),
        title: Text(tx['description'] ?? tx['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(Formatters.formatDateTime(DateTime.parse(tx['createdAt'])), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        trailing: Text('${isInflow ? '+' : '-'}${Formatters.formatCurrency(tx['amount'].toDouble())}',
          style: TextStyle(fontWeight: FontWeight.bold, color: isInflow ? AppTheme.successGreen : Colors.redAccent)),
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Imyitwarire y\'amafaranga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: _stats?['totalDeposits'] ?? 0, color: AppTheme.primaryGreen, title: 'Yinjiye', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12)),
                  PieChartSectionData(value: _stats?['totalWithdrawals'] ?? 0, color: Colors.redAccent, title: 'Yasohotse', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildStatRow('Amafaranga yose yinjiye', _stats?['totalDeposits'] ?? 0, AppTheme.primaryGreen),
          _buildStatRow('Amafaranga yose yasohotse', _stats?['totalWithdrawals'] ?? 0, Colors.redAccent),
          _buildStatRow('Ibikorwa byose', _stats?['transactionCount'] ?? 0, Colors.blueGrey, isCurrency: false),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value, Color color, {bool isCurrency = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(isCurrency ? Formatters.formatCurrency(value.toDouble()) : value.toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showDepositDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eshyuza kuri Wallet'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amafaranga (RWF)', hintText: 'Urugero: 5000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final amount = double.parse(controller.text);
              try {
                final api = ref.read(apiClientProvider);
                await api.deposit(_userId!, amount, 'MTN_MOMO');
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubusabe bwawe bwo kweshura bwakiriwe!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
              }
            },
            child: const Text('Emeza'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kuramo amafaranga'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Amafaranga (RWF)', hintText: 'Urugero: 5000', helperText: 'Urabona: ${Formatters.formatCurrency(_balance)}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final amount = double.parse(controller.text);
              if (amount > _balance) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amafaranga ntahagije'), backgroundColor: Colors.red));
                return;
              }
              try {
                final api = ref.read(apiClientProvider);
                await api.withdraw(_userId!, amount, 'MTN_MOMO');
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubusabe bwawe bwo gukuraho bwakiriwe!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
              }
            },
            child: const Text('Emeza'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
