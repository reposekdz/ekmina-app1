import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class ContributionsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String membershipId;
  final String userId;
  
  const ContributionsScreen({super.key, required this.groupId, required this.membershipId, required this.userId});

  @override
  ConsumerState<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends ConsumerState<ContributionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _contributions = [];
  bool _loading = true;

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
      final api = ref.read(apiClientProvider);
      final response = await api.getContributions(membershipId: widget.membershipId, groupId: widget.groupId);
      if (mounted) {
        setState(() {
          _contributions = response['contributions'] ?? [];
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

  Future<void> _payContribution(double amount) async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.payContribution(widget.membershipId, widget.groupId, amount);
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Ishyuye neza!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
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
        title: const Text('Imisanzu yanjye', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Itegerejwe'),
            Tab(text: 'Yishyuwe'),
            Tab(text: 'Yatinze'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContributionList('PENDING'),
                _buildContributionList('PAID'),
                _buildContributionList('OVERDUE'),
              ],
            ),
    );
  }

  Widget _buildContributionList(String status) {
    final filtered = _contributions.where((c) {
      if (status == 'OVERDUE') {
        return c['status'] == 'PENDING' && DateTime.parse(c['dueDate']).isBefore(DateTime.now());
      }
      if (status == 'PENDING') {
        return c['status'] == 'PENDING' && DateTime.parse(c['dueDate']).isAfter(DateTime.now());
      }
      return c['status'] == status;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Nta misanzu ya $status ihari', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildContributionCard(filtered[index]),
      ),
    );
  }

  Widget _buildContributionCard(dynamic item) {
    final bool isPaid = item['status'] == 'PAID';
    final dueDate = DateTime.parse(item['dueDate']);
    final isOverdue = !isPaid && dueDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPaid ? Colors.green.shade50 : (isOverdue ? Colors.red.shade50 : Colors.grey.shade100)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPaid ? Colors.green.withOpacity(0.1) : (isOverdue ? Colors.red.withOpacity(0.1) : AppTheme.primaryGreen.withOpacity(0.1)),
            shape: BoxShape.circle,
          ),
          child: Icon(isPaid ? Icons.check : Icons.access_time,
            color: isPaid ? Colors.green : (isOverdue ? Colors.red : AppTheme.primaryGreen)),
        ),
        title: Text(Formatters.formatCurrency(item['amount'].toDouble()),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Itariki Ntarengwa: ${Formatters.formatDate(dueDate)}', style: const TextStyle(fontSize: 12)),
            if (item['penaltyApplied'] != null && item['penaltyApplied'] > 0)
              Text('Ihano: ${Formatters.formatCurrency(item['penaltyApplied'].toDouble())}',
                style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: !isPaid ? ElevatedButton(
          onPressed: () => _showPaymentDialog(item),
          style: ElevatedButton.styleFrom(
            backgroundColor: isOverdue ? Colors.red : AppTheme.primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Ishyura', style: TextStyle(color: Colors.white, fontSize: 12)),
        ) : Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: const Text('Yishyuwe', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showPaymentDialog(dynamic item) {
    final amount = item['amount'].toDouble();
    final penalty = (item['penaltyApplied'] ?? 0).toDouble();
    final total = amount + penalty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kwishyura Musanzu', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow('Umukoro:', Formatters.formatCurrency(amount)),
            if (penalty > 0) _buildDialogRow('Ihano:', Formatters.formatCurrency(penalty), color: Colors.red),
            const Divider(height: 24),
            _buildDialogRow('Yose hamwe:', Formatters.formatCurrency(total), isBold: true),
            const SizedBox(height: 16),
            const Text('Aya mafaranga arakurwa muri Wallet yawe.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _payContribution(total);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Ishyura none'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
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
