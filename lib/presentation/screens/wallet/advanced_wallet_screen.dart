import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
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
        final deposits = txList.where((t) => t['type'] == 'DEPOSIT').fold(0.0, (sum, t) => sum + t['amount']);
        final withdrawals = txList.where((t) => t['type'] == 'WITHDRAWAL').fold(0.0, (sum, t) => sum + t['amount']);
        
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

  Future<void> _showDepositDialog() async {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    String paymentMethod = 'MTN_MOMO';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(children: [const Icon(Icons.add_circle, color: AppTheme.primaryGreen), const SizedBox(width: 8), const Text('Shyiramo amafaranga')]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amafaranga (RWF)', prefixIcon: Icon(Icons.money), border: OutlineInputBorder(), helperText: 'Min: 1,000 RWF'),
                  validator: (v) => Validators.validateMinAmount(v, 1000),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(labelText: 'Uburyo bwo kwishyura', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payment)),
                  items: const [
                    DropdownMenuItem(value: 'MTN_MOMO', child: Row(children: [Icon(Icons.phone_android, size: 20, color: Colors.yellow), SizedBox(width: 8), Text('MTN Mobile Money')])),
                    DropdownMenuItem(value: 'AIRTEL_MONEY', child: Row(children: [Icon(Icons.phone_android, size: 20, color: Colors.red), SizedBox(width: 8), Text('Airtel Money')])),
                  ],
                  onChanged: (val) => setDialogState(() => paymentMethod = val!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nimero ya telefoni', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                  validator: Validators.validatePhone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hagarika')),
            ElevatedButton.icon(
              onPressed: () async {
                if (amountController.text.isEmpty) return;
                final biometric = BiometricService();
                final authenticated = await biometric.authenticateForTransaction(double.parse(amountController.text));
                if (authenticated) Navigator.pop(context, true);
              },
              icon: const Icon(Icons.fingerprint),
              label: const Text('Emeza'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            ),
          ],
        ),
      ),
    );

    if (result == true && amountController.text.isNotEmpty) {
      await _processDeposit(double.parse(amountController.text), paymentMethod);
    }
  }

  Future<void> _showWithdrawDialog() async {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    String paymentMethod = 'MTN_MOMO';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(children: [const Icon(Icons.remove_circle, color: Colors.red), const SizedBox(width: 8), const Text('Kuramo amafaranga')]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [const Icon(Icons.account_balance_wallet, color: AppTheme.primaryGreen), const SizedBox(width: 8), Text('Urabona: ${Formatters.formatCurrency(_balance)}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amafaranga (RWF)', prefixIcon: Icon(Icons.money), border: OutlineInputBorder()),
                  validator: (v) => Validators.validateMaxAmount(v, _balance),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(labelText: 'Uburyo bwo kwishyura', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payment)),
                  items: const [
                    DropdownMenuItem(value: 'MTN_MOMO', child: Row(children: [Icon(Icons.phone_android, size: 20, color: Colors.yellow), SizedBox(width: 8), Text('MTN Mobile Money')])),
                    DropdownMenuItem(value: 'AIRTEL_MONEY', child: Row(children: [Icon(Icons.phone_android, size: 20, color: Colors.red), SizedBox(width: 8), Text('Airtel Money')])),
                  ],
                  onChanged: (val) => setDialogState(() => paymentMethod = val!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nimero ya telefoni', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                  validator: Validators.validatePhone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hagarika')),
            ElevatedButton.icon(
              onPressed: () async {
                if (amountController.text.isEmpty) return;
                final amount = double.parse(amountController.text);
                if (amount > _balance) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amafaranga ntahagije'), backgroundColor: Colors.red));
                  return;
                }
                final biometric = BiometricService();
                final authenticated = await biometric.authenticateForTransaction(amount);
                if (authenticated) Navigator.pop(context, true);
              },
              icon: const Icon(Icons.fingerprint),
              label: const Text('Emeza'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );

    if (result == true && amountController.text.isNotEmpty) {
      await _processWithdraw(double.parse(amountController.text), paymentMethod);
    }
  }

  Future<void> _processDeposit(double amount, String method) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.deposit(widget.userId, amount, method, phone: '0780000000');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amafaranga yashyizweho neza!'), backgroundColor: Colors.green));
        _loadWallet();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
    }
  }

  Future<void> _processWithdraw(double amount, String method) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.withdraw(widget.userId, amount, method, '1234', phone: '0780000000');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amafaranga yakuweho neza!'), backgroundColor: Colors.green));
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
        groupName: 'Wallet Transactions',
        totalBalance: _balance,
        memberCount: 1,
        transactions: _transactions.map((t) => {'date': Formatters.formatDate(DateTime.parse(t['createdAt'])), 'type': t['type'], 'amount': t['amount']}).toList(),
      );
      await pdf.sharePdf(file);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Raporo yoherejwe!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Amafaranga yanjye')), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amafaranga yanjye'),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportTransactions, tooltip: 'Raporo'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWallet),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Ahabanza'), Tab(text: 'Imibare'), Tab(text: 'Ibikorwa')]),
      ),
      body: TabBarView(controller: _tabController, children: [_buildOverviewTab(), _buildStatsTab(), _buildTransactionsTab()]),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadWallet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryGreen, Color(0xFF00D68F)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Amafaranga urabona', style: TextStyle(color: Colors.white70, fontSize: 16)), IconButton(icon: const Icon(Icons.visibility, color: Colors.white70), onPressed: () {})]),
                  Text(Formatters.formatCurrency(_balance), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBalanceAction(Icons.add_circle, 'Shyiramo', () => _showDepositDialog()),
                      Container(width: 1, height: 40, color: Colors.white30),
                      _buildBalanceAction(Icons.remove_circle, 'Kuramo', () => _showWithdrawDialog()),
                      Container(width: 1, height: 40, color: Colors.white30),
                      _buildBalanceAction(Icons.send, 'Ohereza', () => context.push('/wallet/send')),
                    ],
                  ),
                ],
              ),
            ),
            _buildQuickStats(),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(children: [Icon(icon, color: Colors.white, size: 28), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Yashyizweho', Formatters.formatCompactNumber(_stats!['totalDeposits']), Icons.arrow_downward, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Yakuweho', Formatters.formatCompactNumber(_stats!['totalWithdrawals']), Icons.arrow_upward, Colors.red)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ibikorwa byihuse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionCard(Icons.group_add, 'Kurema\nitsinda', AppTheme.accentBlue, () => context.push('/groups/create'))),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(Icons.groups, 'Kwinjira mu\ntsinda', AppTheme.warningOrange, () => context.push('/groups'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [Icon(icon, color: color, size: 32), const SizedBox(height: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)]),
      ),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Imibare yawe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildStatRow('Amafaranga yashyizweho', Formatters.formatCurrency(_stats!['totalDeposits']), Icons.arrow_downward, Colors.green),
                const Divider(),
                _buildStatRow('Amafaranga yakuweho', Formatters.formatCurrency(_stats!['totalWithdrawals']), Icons.arrow_upward, Colors.red),
                const Divider(),
                _buildStatRow('Ibikorwa byose', '${_stats!['transactionCount']}', Icons.receipt_long, AppTheme.accentBlue),
                const Divider(),
                _buildStatRow('Impuzandengo', Formatters.formatCurrency(_stats!['avgTransaction']), Icons.analytics, AppTheme.warningOrange),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_transactions.isNotEmpty) _buildChart(),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 12), Expanded(child: Text(label)), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))]),
    );
  }

  Widget _buildChart() {
    final deposits = _transactions.where((t) => t['type'] == 'DEPOSIT').length;
    final withdrawals = _transactions.where((t) => t['type'] == 'WITHDRAWAL').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ubwoko bw\'ibikorwa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: deposits.toDouble(), color: Colors.green, title: 'Yashyizweho\n$deposits', radius: 80, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: withdrawals.toDouble(), color: Colors.red, title: 'Yakuweho\n$withdrawals', radius: 80, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Igihe:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedPeriod,
                items: const [
                  DropdownMenuItem(value: '7', child: Text('Iminsi 7')),
                  DropdownMenuItem(value: '30', child: Text('Iminsi 30')),
                  DropdownMenuItem(value: '90', child: Text('Iminsi 90')),
                  DropdownMenuItem(value: 'all', child: Text('Byose')),
                ],
                onChanged: (value) => setState(() => _selectedPeriod = value!),
              ),
            ],
          ),
        ),
        Expanded(
          child: _transactions.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]), const SizedBox(height: 8), Text('Nta bikorwa', style: TextStyle(color: Colors.grey[600]))]))
              : RefreshIndicator(
                  onRefresh: _loadWallet,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final isDeposit = tx['type'] == 'DEPOSIT';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: isDeposit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), child: Icon(isDeposit ? Icons.arrow_downward : Icons.arrow_upward, color: isDeposit ? Colors.green : Colors.red)),
                          title: Text(tx['description'] ?? tx['type'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(Formatters.formatDateTime(DateTime.parse(tx['createdAt']))),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${isDeposit ? '+' : '-'}${Formatters.formatCurrency(tx['amount'].toDouble())}', style: TextStyle(fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : Colors.red, fontSize: 16)),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: (isDeposit ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(tx['status'] ?? 'COMPLETED', style: TextStyle(fontSize: 10, color: isDeposit ? Colors.green : Colors.red))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
