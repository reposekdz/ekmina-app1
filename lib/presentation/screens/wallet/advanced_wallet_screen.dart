import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class AdvancedWalletScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdvancedWalletScreen({super.key, required this.userId});

  @override
  ConsumerState<AdvancedWalletScreen> createState() => _AdvancedWalletScreenState();
}

class _AdvancedWalletScreenState extends ConsumerState<AdvancedWalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _balance = 0;
  List<dynamic> _transactions = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String _selectedPeriod = '30';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final walletData = await api.getWallet(widget.userId);
      final transactionsData = await api.getTransactions(userId: widget.userId);
      
      if (mounted) {
        final txList = transactionsData['transactions'] as List? ?? [];
        final deposits = txList.where((t) => t['type'] == 'DEPOSIT' || t['type'] == 'CONTRIBUTION').fold(0.0, (sum, t) => sum + (t['amount'] ?? 0));
        final withdrawals = txList.where((t) => t['type'] == 'WITHDRAWAL' || t['type'] == 'LOAN_PAYOUT').fold(0.0, (sum, t) => sum + (t['amount'] ?? 0));
        
        setState(() {
          _balance = (walletData['wallet']?['balance'] ?? 0).toDouble();
          _transactions = txList;
          _stats = {
            'totalDeposits': deposits,
            'totalWithdrawals': withdrawals,
            'transactionCount': txList.length,
            'avgTransaction': txList.isEmpty ? 0.0 : (deposits + withdrawals) / txList.length,
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                pinned: true,
                elevation: 0,
                title: const Text('Wallet Yawe', style: TextStyle(fontWeight: FontWeight.bold)),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.fileText),
                    onPressed: _exportTransactions,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw),
                    onPressed: _loadWallet,
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                  tabs: const [
                    Tab(text: 'Icyerekezo'),
                    Tab(text: 'Imibare'),
                    Tab(text: 'Ibikorwa'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildStatsTab(),
                _buildTransactionsTab(),
              ],
            ),
          ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadWallet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            _buildMainBalanceCard().animate().fadeIn().scale(),
            const SizedBox(height: 24),
            _buildActionGrid().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            _buildQuickStats().animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
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
              Text(
                'Amafaranga arimo',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
              ),
              const Icon(LucideIcons.eye, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.formatCurrency(_balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactAction(LucideIcons.plusCircle, 'Shyiramo', _showDepositDialog),
              _buildCompactAction(LucideIcons.minusCircle, 'Kuramo', _showWithdrawDialog),
              _buildCompactAction(LucideIcons.send, 'Ohereza', () => context.push('/wallet/send')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ibikorwa byihuse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFancyActionCard(
                  'Kurema Itsinda',
                  'Tangira itsinda rishya',
                  LucideIcons.users,
                  AppTheme.primaryBlue,
                  () => context.push('/groups/create'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFancyActionCard(
                  'Injira',
                  'Shaka amatsinda',
                  LucideIcons.search,
                  AppTheme.primaryYellow,
                  () => context.push('/groups/public'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFancyActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              'Yashyizweho',
              Formatters.formatCompactNumber(_stats?['totalDeposits'] ?? 0),
              LucideIcons.arrowDownLeft,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatTile(
              'Yakuweho',
              Formatters.formatCompactNumber(_stats?['totalWithdrawals'] ?? 0),
              LucideIcons.arrowUpRight,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('Imibare Yose', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildDetailedStatRow('Amafaranga Yashyizweho', _stats?['totalDeposits'] ?? 0, Colors.green),
                  const Divider(height: 32),
                  _buildDetailedStatRow('Amafaranga Yakuweho', _stats?['totalWithdrawals'] ?? 0, Colors.orange),
                  const Divider(height: 32),
                  _buildDetailedStatRow('Umubare w\'ibikorwa', (_stats?['transactionCount'] ?? 0).toDouble(), AppTheme.primaryBlue, isCurrency: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_transactions.isNotEmpty) _buildEnhancedChart(),
        ],
      ),
    );
  }

  Widget _buildDetailedStatRow(String label, double value, Color color, {bool isCurrency = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          isCurrency ? Formatters.formatCurrency(value) : value.toInt().toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
      ],
    );
  }

  Widget _buildEnhancedChart() {
    final deposits = _transactions.where((t) => t['type'] == 'DEPOSIT' || t['type'] == 'CONTRIBUTION').length;
    final withdrawals = _transactions.where((t) => t['type'] == 'WITHDRAWAL' || t['type'] == 'LOAN_PAYOUT').length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ubwoko bw\'ibikorwa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: deposits.toDouble(),
                    color: Colors.green,
                    title: 'D: $deposits',
                    radius: 60,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: withdrawals.toDouble(),
                    color: Colors.orange,
                    title: 'W: $withdrawals',
                    radius: 60,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_transactions.length} Ibyakozwe',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: '7', child: Text('Iminsi 7')),
                      DropdownMenuItem(value: '30', child: Text('Iminsi 30')),
                      DropdownMenuItem(value: 'all', child: Text('Byose')),
                    ],
                    onChanged: (v) => setState(() => _selectedPeriod = v!),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _transactions.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.receipt, size: 48, color: Colors.grey[300]), const SizedBox(height: 16), const Text('Nta bikorwa bihari', style: TextStyle(color: Colors.grey))]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final isDeposit = tx['type'] == 'DEPOSIT' || tx['type'] == 'CONTRIBUTION';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade50),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isDeposit ? Colors.green : Colors.orange).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDeposit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                            color: isDeposit ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(tx['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(Formatters.formatDate(DateTime.parse(tx['createdAt'])), style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          '${isDeposit ? "+" : "-"}${tx['amount']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDeposit ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                  },
                ),
        ),
      ],
    );
  }

  // --- Dialogs & Business Logic ---
  
  Future<void> _showDepositDialog() async {
    final amountController = TextEditingController();
    String provider = 'MTN';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Shyiramo Amafaranga', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Injiza amafaranga wifuza gushyira kuri wallet yawe.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              
              const Text('Uburyo ukoresha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildProviderOption('MTN MoMo', 'MTN', provider == 'MTN', (val) => setModalState(() => provider = val!)),
                  const SizedBox(width: 12),
                  _buildProviderOption('Airtel Money', 'AIRTEL', provider == 'AIRTEL', (val) => setModalState(() => provider = val!)),
                ],
              ),
              
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Amafaranga (RWF)',
                  prefixIcon: Icon(LucideIcons.banknote),
                  hintText: 'Urugero: 5000',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isNotEmpty) {
                      Navigator.pop(context);
                      await _processDeposit(double.parse(amountController.text), provider);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Emeza Ubike', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderOption(String label, String value, bool isSelected, ValueChanged<String?> onChanged) {
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade200, width: 2),
          ),
          child: Center(
            child: Text(
              label, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWithdrawDialog() async {
    final amountController = TextEditingController();
    String provider = 'MTN';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Kuramo Amafaranga', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Balance ihari: ${Formatters.formatCurrency(_balance)}', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              
              const Text('Uburyo ukoresha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildProviderOption('MTN MoMo', 'MTN', provider == 'MTN', (val) => setModalState(() => provider = val!)),
                  const SizedBox(width: 12),
                  _buildProviderOption('Airtel Money', 'AIRTEL', provider == 'AIRTEL', (val) => setModalState(() => provider = val!)),
                ],
              ),
              
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Amafaranga (RWF)',
                  prefixIcon: Icon(LucideIcons.banknote),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () async {
                    if (amountController.text.isNotEmpty) {
                      Navigator.pop(context);
                      await _processWithdraw(double.parse(amountController.text), provider);
                    }
                  },
                  child: const Text('Kuramo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processDeposit(double amount, String method) async {
    try {
      final api = ref.read(apiClientProvider);
      // In a real app, we would get the phone from secure storage
      final storage = SecureStorageService();
      final phone = await storage.getUserPhone() ?? '0780000000';
      
      await api.deposit(widget.userId, amount, method, phone: phone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ibikorwa byatangiye, emeza kuri telefoni yawe!'), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadWallet();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
    }
  }

  Future<void> _processWithdraw(double amount, String method) async {
    try {
      final api = ref.read(apiClientProvider);
      final storage = SecureStorageService();
      final phone = await storage.getUserPhone() ?? '0780000000';
      
      await api.withdraw(widget.userId, amount, method, '1234', phone: phone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kukura amafaranga byagenze neza!'), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadWallet();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportTransactions() async {
    try {
      final pdf = PdfService();
      final file = await pdf.generateGroupReport(
        groupName: 'Raporo ya Wallet',
        totalBalance: _balance,
        memberCount: 1,
        transactions: _transactions.map((t) => {'date': Formatters.formatDate(DateTime.parse(t['createdAt'])), 'type': t['type'], 'amount': t['amount']}).toList(),
      );
      await pdf.sharePdf(file);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ntibishoboye gukora raporo'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
