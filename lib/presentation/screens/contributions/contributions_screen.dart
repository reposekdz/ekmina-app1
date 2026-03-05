import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  Future<void> _payContribution(double amount, String contributionId) async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.payContribution(widget.membershipId, widget.groupId, amount);
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Umusanzu wishyuwe neza!'), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.handleError(e)), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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
            title: const Text('Imisanzu yanjye', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _loadData),
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
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Itegerejwe'),
                    Tab(text: 'Yishyuwe'),
                    Tab(text: 'Yatinze'),
                  ],
                ),
              ),
            ),
          ),
        ],
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
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.coins, size: 64, color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Text(
              status == 'PAID' ? 'Nta misanzu wishyuye iragaragara' : 'Nta misanzu itegerejwe ihari', 
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildContributionCard(filtered[index], index),
      ),
    );
  }

  Widget _buildContributionCard(dynamic item, int index) {
    final bool isPaid = item['status'] == 'PAID';
    final dueDate = DateTime.parse(item['dueDate']);
    final isOverdue = !isPaid && dueDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isPaid ? Colors.green : (isOverdue ? Colors.red : AppTheme.primaryBlue)).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPaid ? LucideIcons.checkCircle2 : LucideIcons.clock,
            color: isPaid ? Colors.green : (isOverdue ? Colors.red : AppTheme.primaryBlue),
            size: 24,
          ),
        ),
        title: Text(
          Formatters.formatCurrency(item['amount'].toDouble()),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Kugeza: ${Formatters.formatDate(dueDate)}', 
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (item['penaltyApplied'] != null && item['penaltyApplied'] > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ihano: ${Formatters.formatCurrency(item['penaltyApplied'].toDouble())}',
                  style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        trailing: !isPaid ? ElevatedButton(
          onPressed: () => _showPaymentDialog(item),
          style: ElevatedButton.styleFrom(
            backgroundColor: isOverdue ? Colors.orange : AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
          ),
          child: const Text('Ishyura', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ) : Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1), 
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Yishyuwe', 
            style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
  }

  void _showPaymentDialog(dynamic item) {
    final amount = item['amount'].toDouble();
    final penalty = (item['penaltyApplied'] ?? 0).toDouble();
    final total = amount + penalty;

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
            const Text('Kwishyura Umusanzu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1)),
            const SizedBox(height: 24),
            _buildDialogRow('Umusanzu usanzwe:', Formatters.formatCurrency(amount)),
            if (penalty > 0) _buildDialogRow('Amande (Ihano):', Formatters.formatCurrency(penalty), color: Colors.red),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),
            _buildDialogRow('Yose hamwe:', Formatters.formatCurrency(total), isBold: true, fontSize: 20),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Aya mafaranga arakurwa kuri Wallet yawe ako kanya.',
                      style: TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _payContribution(total, item['id']);
                },
                child: const Text('Emeza Kwishyura', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isBold = false, Color? color, double fontSize = 15}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: fontSize)),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: color ?? (isBold ? AppTheme.primaryBlue : Colors.black),
              fontSize: fontSize,
            ),
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
