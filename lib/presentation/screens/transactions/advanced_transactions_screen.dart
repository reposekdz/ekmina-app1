import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      appBar: AppBar(
        title: const Text('Amateka y\'ibyakozwe', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTransactions),
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCards(),
                _buildTabBar(),
                Expanded(child: _buildTransactionsList()),
              ],
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildSummaryCard('Yinjiye', Formatters.formatCurrency(_totalIncome), AppTheme.successGreen, Icons.arrow_downward)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard('Yasohotse', Formatters.formatCurrency(_totalExpense), Colors.redAccent, Icons.arrow_upward)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Byose'),
          Tab(text: 'Eshyuza'),
          Tab(text: 'Kuramo'),
          Tab(text: 'Imisanzu'),
          Tab(text: 'Inguzanyo'),
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
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Nta bikorwa byabonetse', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final tx = filtered[index];
          final date = DateTime.parse(tx['createdAt']);

          if (index == 0 || _getDateLabel(date) != _getDateLabel(DateTime.parse(filtered[index - 1]['createdAt']))) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text(_getDateLabel(date), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                _buildTransactionCard(tx),
              ],
            );
          }
          return _buildTransactionCard(tx);
        },
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) return 'Uyu munsi';
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) return 'Ejo hashize';
    return DateFormat('dd MMM yyyy').format(date);
  }

  Widget _buildTransactionCard(dynamic tx) {
    final type = tx['type'] as String;
    final amount = (tx['amount'] ?? 0).toDouble();
    final isInflow = type == 'DEPOSIT' || type == 'CONTRIBUTION' || type == 'LOAN_DISBURSEMENT' || type == 'DIVIDEND_PAYMENT';

    IconData icon;
    Color color;

    switch (type) {
      case 'DEPOSIT': icon = Icons.add_circle_outline; color = AppTheme.primaryGreen; break;
      case 'WITHDRAWAL': icon = Icons.remove_circle_outline; color = Colors.orange; break;
      case 'CONTRIBUTION': icon = Icons.savings_outlined; color = AppTheme.accentBlue; break;
      case 'LOAN_DISBURSEMENT': icon = Icons.request_quote_outlined; color = Colors.purple; break;
      case 'LOAN_REPAYMENT': icon = Icons.payments_outlined; color = Colors.indigo; break;
      case 'PENALTY': icon = Icons.warning_amber_rounded; color = Colors.redAccent; break;
      default: icon = Icons.swap_horiz; color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () => _showDetails(tx),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(tx['description'] ?? type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(DateFormat('HH:mm').format(DateTime.parse(tx['createdAt'])), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${isInflow ? '+' : '-'}${Formatters.formatCurrency(amount.abs())}',
              style: TextStyle(fontWeight: FontWeight.bold, color: isInflow ? AppTheme.successGreen : Colors.redAccent)),
            Text(tx['status'] ?? 'COMPLETED', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  void _showDetails(dynamic tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Amakuru y\'igikorwa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildDetailRow('Ubwoko', tx['type']),
            _buildDetailRow('Amafaranga', Formatters.formatCurrency(tx['amount'].toDouble())),
            _buildDetailRow('Ibisobanuro', tx['description'] ?? 'Nta bisobanuro'),
            _buildDetailRow('Itariki', Formatters.formatDateTime(DateTime.parse(tx['createdAt']))),
            _buildDetailRow('Uko bimeze', tx['status'] ?? 'BYARANGIYE'),
            if (tx['reference'] != null) _buildDetailRow('Reference', tx['reference']),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('FUNGA'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
