import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class AdvancedTransactionsScreen extends ConsumerStatefulWidget {
  final String? userId;
  final String? groupId;
  const AdvancedTransactionsScreen({super.key, this.userId, this.groupId});

  @override
  ConsumerState<AdvancedTransactionsScreen> createState() => _AdvancedTransactionsScreenState();
}

class _AdvancedTransactionsScreenState extends ConsumerState<AdvancedTransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _transactions = [];
  bool _loading = true;
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getTransactions(userId: widget.userId, groupId: widget.groupId);

      if (mounted) {
        final txList = response['transactions'] as List? ?? [];
        double income = 0;
        double expense = 0;

        for (var tx in txList) {
          final amount = (tx['amount'] ?? 0).toDouble();
          final type = tx['type'] as String;
          if (type == 'DEPOSIT' || type == 'CONTRIBUTION' || type == 'LOAN_DISBURSEMENT' || type == 'DIVIDEND_PAYMENT') {
            income += amount;
          } else {
            expense += amount.abs();
          }
        }

        setState(() {
          _transactions = txList;
          _totalIncome = income;
          _totalExpense = expense;
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            title: const Text('Amateka y\'ibyakozwe', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _loadTransactions),
              IconButton(icon: const Icon(LucideIcons.download), onPressed: () {}),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Byose'),
                    Tab(text: 'Eshyuza'),
                    Tab(text: 'Kuramo'),
                    Tab(text: 'Imisanzu'),
                    Tab(text: 'Inguzanyo'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildSummarySection().animate().fadeIn().slideY(begin: 0.1),
                  Expanded(child: _buildTransactionsList()),
                ],
              ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildGradientSummaryCard(
              'Yinjiye', 
              Formatters.formatCurrency(_totalIncome), 
              AppTheme.successGradient, 
              LucideIcons.arrowDownLeft,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildGradientSummaryCard(
              'Yasohotse', 
              Formatters.formatCurrency(_totalExpense), 
              const LinearGradient(colors: [Colors.orange, Colors.deepOrange]), 
              LucideIcons.arrowUpRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientSummaryCard(String label, String amount, Gradient gradient, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildList('ALL'),
        _buildList('DEPOSIT'),
        _buildList('WITHDRAWAL'),
        _buildList('CONTRIBUTION'),
        _buildList('LOAN'),
      ],
    );
  }

  Widget _buildList(String filterType) {
    final filtered = filterType == 'ALL'
        ? _transactions
        : _transactions.where((t) => t['type'] == filterType || (filterType == 'LOAN' && (t['type'] == 'LOAN_DISBURSEMENT' || t['type'] == 'LOAN_REPAYMENT'))).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.receipt, size: 64, color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Text('Nta bikorwa byabonetse', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      ).animate().fadeIn();
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final tx = filtered[index];
          final date = DateTime.parse(tx['createdAt']);

          bool showDateHeader = false;
          if (index == 0 || _getDateLabel(date) != _getDateLabel(DateTime.parse(filtered[index - 1]['createdAt']))) {
            showDateHeader = true;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateHeader)
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
                  child: Text(
                    _getDateLabel(date), 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400, fontSize: 12, letterSpacing: 1),
                  ),
                ),
              _buildTransactionCard(tx, index),
            ],
          );
        },
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) return 'UYU MUNSI';
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) return 'EJO HASHIZE';
    return DateFormat('dd MMMM yyyy').format(date).toUpperCase();
  }

  Widget _buildTransactionCard(dynamic tx, int index) {
    final type = tx['type'] as String;
    final amount = (tx['amount'] ?? 0).toDouble();
    final isInflow = type == 'DEPOSIT' || type == 'CONTRIBUTION' || type == 'LOAN_DISBURSEMENT' || type == 'DIVIDEND_PAYMENT';

    IconData icon;
    Color color;

    switch (type) {
      case 'DEPOSIT': icon = LucideIcons.plusCircle; color = AppTheme.primaryBlue; break;
      case 'WITHDRAWAL': icon = LucideIcons.minusCircle; color = Colors.orange; break;
      case 'CONTRIBUTION': icon = LucideIcons.landmark; color = AppTheme.primaryGreen; break;
      case 'LOAN_DISBURSEMENT': icon = LucideIcons.landmark; color = AppTheme.accentIndigo; break;
      case 'LOAN_REPAYMENT': icon = LucideIcons.creditCard; color = Colors.blue; break;
      case 'PENALTY': icon = LucideIcons.alertTriangle; color = Colors.red; break;
      default: icon = LucideIcons.arrowLeftRight; color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: ListTile(
        onTap: () => _showDetails(tx),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          tx['description'] ?? type, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), 
          maxLines: 1, 
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('HH:mm').format(DateTime.parse(tx['createdAt'])), 
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isInflow ? '+' : '-'}${Formatters.formatCurrency(amount.abs()).replaceAll('RWF', '')}',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                color: isInflow ? Colors.green : Colors.orange,
              ),
            ),
            Text(
              tx['status'] ?? 'SUCCESS', 
              style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index % 10 * 50).ms).slideX(begin: 0.05);
  }

  void _showDetails(dynamic tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 32),
            const Text('Amakuru y\'igikorwa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildDetailRow('Ubwoko', tx['type']),
            _buildDetailRow('Amafaranga', Formatters.formatCurrency((tx['amount'] ?? 0).toDouble())),
            _buildDetailRow('Ibisobanuro', tx['description'] ?? 'Nta bisobanuro'),
            _buildDetailRow('Itariki', Formatters.formatDateTime(DateTime.parse(tx['createdAt']))),
            _buildDetailRow('Uko bimeze', tx['status'] ?? 'BYARANGIYE'),
            if (tx['reference'] != null) _buildDetailRow('Reference', tx['reference']),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('FUNGA'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
