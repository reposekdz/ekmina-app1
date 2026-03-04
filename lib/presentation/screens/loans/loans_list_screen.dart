import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';

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
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.getLoans(membershipId: widget.userId);
      if (mounted) setState(() {_loans = data['loans'] ?? []; _loading = false;});
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
      appBar: AppBar(
        title: const Text('Inguzanyo zanjye'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Zikoreshwa'), Tab(text: 'Zitegerejwe'), Tab(text: 'Zarangiye'), Tab(text: 'Zanzwe')],
        ),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : TabBarView(
        controller: _tabController,
        children: [_buildLoansList('ACTIVE'), _buildLoansList('PENDING'), _buildLoansList('COMPLETED'), _buildLoansList('REJECTED')],
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
            Icon(Icons.request_quote_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nta nguzanyo $status', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLoans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loans.length,
        itemBuilder: (context, index) => _buildLoanCard(loans[index]),
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final status = loan['status'] as String;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'ACTIVE': statusColor = const Color(0xFF00A86B); statusIcon = Icons.check_circle; break;
      case 'PENDING': statusColor = Colors.orange; statusIcon = Icons.pending; break;
      case 'COMPLETED': statusColor = Colors.blue; statusIcon = Icons.done_all; break;
      default: statusColor = Colors.red; statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showLoanDetails(loan),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loan['group']?['name'] ?? 'Itsinda', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Yasabwe: ${Formatters.formatDate(DateTime.parse(loan['requestedAt']))}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(child: _buildLoanInfo('Inguzanyo', Formatters.formatCurrency(loan['amount'].toDouble()))),
                  Expanded(child: _buildLoanInfo('Yose hamwe', Formatters.formatCurrency(loan['totalAmount'].toDouble()))),
                ],
              ),
              if (status == 'ACTIVE') ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: loan['amountPaid'] / loan['totalAmount'],
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Wishyuye: ${Formatters.formatCurrency(loan['amountPaid'].toDouble())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${loan['duration']} amezi asigaye', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
              if (status == 'PENDING') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Itegereje kwemezwa', style: TextStyle(color: Colors.orange.shade900))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
    );
  }

  void _showLoanDetails(Map<String, dynamic> loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Amakuru y\'inguzanyo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildDetailRow('Itsinda', loan['group']?['name'] ?? 'N/A'),
              _buildDetailRow('Inguzanyo', Formatters.formatCurrency(loan['amount'].toDouble())),
              _buildDetailRow('Inyungu', Formatters.formatCurrency(loan['interest'].toDouble())),
              _buildDetailRow('Yose hamwe', Formatters.formatCurrency(loan['totalAmount'].toDouble())),
              if (loan['amountPaid'] != null) _buildDetailRow('Wishyuye', Formatters.formatCurrency(loan['amountPaid'].toDouble())),
              _buildDetailRow('Igihe', '${loan['duration']} amezi'),
              _buildDetailRow('Uko bimeze', loan['status']),
              _buildDetailRow('Yasabwe', Formatters.formatDate(DateTime.parse(loan['requestedAt']))),
              if (loan['status'] == 'ACTIVE') ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showMakePaymentDialog(loan);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Kwishyura'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]),
    );
  }

  void _showMakePaymentDialog(Map<String, dynamic> loan) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kwishyura inguzanyo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amafaranga (RWF)', prefixIcon: Icon(Icons.money), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Text('Asigaye: ${Formatters.formatCurrency((loan['totalAmount'] - loan['amountPaid']).toDouble())}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty) return;
              try {
                final api = ref.read(apiClientProvider);
                await api.payLoan(loan['id'], double.parse(amountController.text));
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wishyuye neza!'), backgroundColor: Colors.green));
                  _loadLoans();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
              }
            },
            child: const Text('Kwishyura'),
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
