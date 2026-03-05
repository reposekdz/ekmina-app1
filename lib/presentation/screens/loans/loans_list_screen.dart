import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class LoansListScreen extends ConsumerStatefulWidget {
  final String userId;
  const LoansListScreen({super.key, required this.userId});

  @override
  ConsumerState<LoansListScreen> createState() => _LoansListScreenState();
}

class _LoansListScreenState extends ConsumerState<LoansListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.getLoans(membershipId: widget.userId);
      if (mounted) {
        setState(() {
          _loans = data['loans'] ?? []; 
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
            title: const Text('Inguzanyo zanjye', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _loadLoans),
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
                    Tab(text: 'Zikoreshwa'),
                    Tab(text: 'Zitegerejwe'),
                    Tab(text: 'Zarangiye'),
                    Tab(text: 'Zanzwe'),
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
                  _buildLoansList('ACTIVE'),
                  _buildLoansList('PENDING'),
                  _buildLoansList('COMPLETED'),
                  _buildLoansList('REJECTED'),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRequestLoanOptions(),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Saba Inguzanyo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBlue,
      ).animate().scale(delay: 400.ms),
    );
  }

  void _showRequestLoanOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saba Inguzanyo mu Itsinda', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Hitamo itsinda wifuza gukuramo inguzanyo.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            // In a real app, you would list the user's groups here
            _buildGroupSelectItem('Itsinda rya Kigali Savings', 'Escrow: 500,000 RWF'),
            _buildGroupSelectItem('E-Kimina Vision Group', 'Escrow: 1,200,000 RWF'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSelectItem(String name, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: AppTheme.primaryBlue, child: Icon(LucideIcons.users, color: Colors.white, size: 20)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
        onTap: () {
          Navigator.pop(context);
          // Navigate to request form
        },
      ),
    );
  }

  Widget _buildLoansList(String status) {
    final loans = _loans.where((l) => l['status'] == status).toList();

    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
              child: Icon(LucideIcons.landmark, size: 64, color: Colors.grey.shade200),
            ),
            const SizedBox(height: 16),
            Text('Nta nguzanyo zishyizwe mu cyiciro cya $status', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
      ).animate().fadeIn();
    }

    return RefreshIndicator(
      onRefresh: _loadLoans,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: loans.length,
        itemBuilder: (context, index) => _buildLoanCard(loans[index], index),
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan, int index) {
    final status = loan['status'] as String;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'ACTIVE': statusColor = AppTheme.primaryBlue; statusIcon = LucideIcons.checkCircle2; break;
      case 'PENDING': statusColor = Colors.orange; statusIcon = LucideIcons.clock; break;
      case 'COMPLETED': statusColor = Colors.green; statusIcon = LucideIcons.award; break;
      default: statusColor = Colors.red; statusIcon = LucideIcons.xCircle;
    }

    final progress = (loan['amountPaid'] ?? 0) / (loan['totalAmount'] ?? 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showLoanDetails(loan),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loan['group']?['name'] ?? 'Itsinda', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Yasabwe: ${Formatters.formatDate(DateTime.parse(loan['requestedAt']))}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  _buildStatusChip(status, statusColor),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLoanInfo('Inguzanyo', Formatters.formatCurrency(loan['amount'].toDouble())),
                  _buildLoanInfo('Yose hamwe', Formatters.formatCurrency(loan['totalAmount'].toDouble())),
                ],
              ),
              if (status == 'ACTIVE') ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Wishyuye: ${Formatters.formatCurrency(loan['amountPaid'].toDouble())}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                    Text('${(progress * 100).toInt()}% Byishyuwe', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildLoanInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  void _showLoanDetails(Map<String, dynamic> loan) {
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
            const Text('Amakuru y\'inguzanyo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildDetailRow('Itsinda', loan['group']?['name'] ?? 'N/A'),
            _buildDetailRow('Inguzanyo', Formatters.formatCurrency(loan['amount'].toDouble())),
            _buildDetailRow('Inyungu', Formatters.formatCurrency(loan['interest'].toDouble())),
            _buildDetailRow('Yose hamwe', Formatters.formatCurrency(loan['totalAmount'].toDouble())),
            _buildDetailRow('Igihe', '${loan['duration']} amezi'),
            _buildDetailRow('Uko bimeze', loan['status']),
            const SizedBox(height: 40),
            if (loan['status'] == 'ACTIVE')
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showMakePaymentDialog(loan);
                  },
                  child: const Text('Ishyura none'),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)), 
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))
        ],
      ),
    );
  }

  void _showMakePaymentDialog(Map<String, dynamic> loan) {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 30, left: 30, right: 30),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kwishyura Inguzanyo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amafaranga (RWF)',
                prefixIcon: Icon(LucideIcons.banknote),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (amountController.text.isEmpty) return;
                  try {
                    final api = ref.read(apiClientProvider);
                    await api.payLoan(loan['id'], double.parse(amountController.text));
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ishyuye neza!'), backgroundColor: Colors.green));
                      _loadLoans();
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Emeza Kwishyura'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
