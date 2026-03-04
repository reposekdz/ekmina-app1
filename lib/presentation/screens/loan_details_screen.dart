import 'package:flutter/material.dart';

class LoanDetailsScreen extends StatefulWidget {
  final String loanId;
  final String groupName;
  final double loanAmount;
  final double totalRepayment;
  final double paidAmount;
  final int duration;
  final String status;

  const LoanDetailsScreen({
    super.key,
    required this.loanId,
    required this.groupName,
    required this.loanAmount,
    required this.totalRepayment,
    required this.paidAmount,
    required this.duration,
    required this.status,
  });

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get remainingAmount => widget.totalRepayment - widget.paidAmount;
  double get progress => widget.paidAmount / widget.totalRepayment;
  double get monthlyPayment => widget.totalRepayment / widget.duration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Loan Details', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareLoanDetails),
        ],
      ),
      body: Column(
        children: [
          _buildLoanSummaryCard(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildLoanSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A86B), Color(0xFF00D68F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A86B).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loan Amount', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.loanAmount.toStringAsFixed(0)} RWF',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.status,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Group: ${widget.groupName}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildInfoItem('Total Repayment', '${widget.totalRepayment.toStringAsFixed(0)} RWF')),
              Expanded(child: _buildInfoItem('Paid', '${widget.paidAmount.toStringAsFixed(0)} RWF')),
              Expanded(child: _buildInfoItem('Remaining', '${remainingAmount.toStringAsFixed(0)} RWF')),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progress', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF00A86B);
      case 'pending':
        return const Color(0xFFFFB800);
      case 'completed':
        return const Color(0xFF0066CC);
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF00A86B),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Payment Schedule'),
          Tab(text: 'Details'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPaymentSchedule(),
        _buildLoanDetails(),
      ],
    );
  }

  Widget _buildPaymentSchedule() {
    final payments = List.generate(widget.duration, (index) {
      final isPaid = (index + 1) * monthlyPayment <= widget.paidAmount;
      final isOverdue = !isPaid && index < 2; // Mock overdue logic
      return {
        'month': index + 1,
        'amount': monthlyPayment,
        'dueDate': 'Feb ${15 + index}, 2026',
        'isPaid': isPaid,
        'isOverdue': isOverdue,
      };
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentItem(
          payment['month'] as int,
          payment['amount'] as double,
          payment['dueDate'] as String,
          payment['isPaid'] as bool,
          payment['isOverdue'] as bool,
        );
      },
    );
  }

  Widget _buildPaymentItem(int month, double amount, String dueDate, bool isPaid, bool isOverdue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? const Color(0xFF00A86B) : (isOverdue ? Colors.red : Colors.transparent),
          width: isPaid || isOverdue ? 2 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPaid
                  ? const Color(0xFF00A86B).withOpacity(0.1)
                  : (isOverdue ? Colors.red.withOpacity(0.1) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isPaid
                  ? const Icon(Icons.check_circle, color: Color(0xFF00A86B))
                  : (isOverdue
                      ? const Icon(Icons.warning, color: Colors.red)
                      : Text('$month', style: const TextStyle(fontWeight: FontWeight.bold))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment $month',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: $dueDate',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${amount.toStringAsFixed(0)} RWF',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF00A86B)
                      : (isOverdue ? Colors.red : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPaid ? 'Paid' : (isOverdue ? 'Overdue' : 'Pending'),
                  style: TextStyle(
                    color: isPaid || isOverdue ? Colors.white : Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetails() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDetailCard('Loan Information', [
          {'label': 'Loan ID', 'value': widget.loanId},
          {'label': 'Group', 'value': widget.groupName},
          {'label': 'Status', 'value': widget.status},
          {'label': 'Application Date', 'value': 'Jan 10, 2026'},
          {'label': 'Approval Date', 'value': 'Jan 12, 2026'},
        ]),
        const SizedBox(height: 16),
        _buildDetailCard('Amount Details', [
          {'label': 'Principal Amount', 'value': '${widget.loanAmount.toStringAsFixed(0)} RWF'},
          {'label': 'Interest Rate', 'value': '10%'},
          {'label': 'Interest Amount', 'value': '${(widget.totalRepayment - widget.loanAmount).toStringAsFixed(0)} RWF'},
          {'label': 'Total Repayment', 'value': '${widget.totalRepayment.toStringAsFixed(0)} RWF'},
        ]),
        const SizedBox(height: 16),
        _buildDetailCard('Payment Details', [
          {'label': 'Duration', 'value': '${widget.duration} months'},
          {'label': 'Monthly Payment', 'value': '${monthlyPayment.toStringAsFixed(0)} RWF'},
          {'label': 'Amount Paid', 'value': '${widget.paidAmount.toStringAsFixed(0)} RWF'},
          {'label': 'Remaining Balance', 'value': '${remainingAmount.toStringAsFixed(0)} RWF'},
        ]),
        const SizedBox(height: 16),
        _buildDetailCard('Guarantors', [
          {'label': 'Jean Mukama', 'value': '120 shares'},
          {'label': 'Marie Uwase', 'value': '95 shares'},
        ]),
      ],
    );
  }

  Widget _buildDetailCard(String title, List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['label']!, style: TextStyle(color: Colors.grey[600])),
                    Text(item['value']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (widget.status.toLowerCase() == 'completed') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: const Text(
          'Loan Completed ✓',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00A86B)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _requestExtension,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Request Extension'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _makePayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Make Payment'),
            ),
          ),
        ],
      ),
    );
  }

  void _makePayment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Make Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Monthly Payment: ${monthlyPayment.toStringAsFixed(0)} RWF', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Remaining Balance: ${remainingAmount.toStringAsFixed(0)} RWF', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              const TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  suffixText: 'RWF',
                  prefixIcon: Icon(Icons.money),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSuccessDialog('Payment successful!');
                  },
                  child: const Text('Confirm Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _requestExtension() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Extension'),
        content: const Text('Do you want to request a loan extension? This will be reviewed by group admins.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessDialog('Extension request submitted!');
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _shareLoanDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing loan details...')),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFF00A86B), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}
