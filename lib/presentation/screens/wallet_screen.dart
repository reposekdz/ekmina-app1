import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isBalanceVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          _buildQuickActions(),
          const SizedBox(height: 16),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
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
          const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            _isBalanceVisible ? '250,000 RWF' : '••••••',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildBalanceItem('Available', '200,000 RWF')),
              Container(width: 1, height: 30, color: Colors.white30),
              Expanded(child: _buildBalanceItem('Locked', '50,000 RWF')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String amount) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          _isBalanceVisible ? amount : '••••••',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildActionButton('Deposit', Icons.add_circle, const Color(0xFF00A86B), _showDepositSheet)),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton('Withdraw', Icons.remove_circle, const Color(0xFFFFB800), _showWithdrawSheet)),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton('Transfer', Icons.swap_horiz, const Color(0xFF0066CC), _showTransferSheet)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
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
          Tab(text: 'All'),
          Tab(text: 'Income'),
          Tab(text: 'Expense'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTransactionList('all'),
        _buildTransactionList('income'),
        _buildTransactionList('expense'),
      ],
    );
  }

  Widget _buildTransactionList(String type) {
    final transactions = [
      {'type': 'Deposit', 'group': 'Abahizi Kimina', 'amount': '5,000', 'date': 'Jan 15, 2026', 'isCredit': true},
      {'type': 'Loan Payment', 'group': 'Young Pros 2026', 'amount': '10,000', 'date': 'Jan 14, 2026', 'isCredit': false},
      {'type': 'Withdrawal', 'group': 'Abahizi Kimina', 'amount': '3,000', 'date': 'Jan 13, 2026', 'isCredit': false},
      {'type': 'Deposit', 'group': 'Abahizi Kimina', 'amount': '5,000', 'date': 'Jan 10, 2026', 'isCredit': true},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _buildTransactionItem(
          tx['type'] as String,
          tx['group'] as String,
          tx['amount'] as String,
          tx['date'] as String,
          tx['isCredit'] as bool,
        );
      },
    );
  }

  Widget _buildTransactionItem(String type, String group, String amount, String date, bool isCredit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFF00A86B).withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? const Color(0xFF00A86B) : Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(group, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(date, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}$amount RWF',
            style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? const Color(0xFF00A86B) : Colors.red),
          ),
        ],
      ),
    );
  }

  void _showDepositSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDepositSheet(),
    );
  }

  Widget _buildDepositSheet() {
    final amountController = TextEditingController();
    String selectedMethod = 'MTN MoMo';

    return Container(
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
                const Text('Deposit Money', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter amount',
                suffixText: 'RWF',
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildPaymentMethod('MTN MoMo', 'assets/mtn.png', selectedMethod == 'MTN MoMo'),
            const SizedBox(height: 8),
            _buildPaymentMethod('Airtel Money', 'assets/airtel.png', selectedMethod == 'Airtel Money'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSuccessDialog('Deposit initiated successfully!');
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(String name, String logo, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? const Color(0xFF00A86B) : Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: isSelected ? const Color(0xFF00A86B) : Colors.grey),
          const SizedBox(width: 12),
          Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF00A86B) : Colors.black)),
          const Spacer(),
          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF00A86B)),
        ],
      ),
    );
  }

  void _showWithdrawSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWithdrawSheet(),
    );
  }

  Widget _buildWithdrawSheet() {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    return Container(
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
                const Text('Withdraw Money', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter amount', suffixText: 'RWF', prefixIcon: Icon(Icons.money)),
            ),
            const SizedBox(height: 16),
            const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+250 788 123 456', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSuccessDialog('Withdrawal request submitted!');
                },
                child: const Text('Withdraw'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTransferSheet(),
    );
  }

  Widget _buildTransferSheet() {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    return Container(
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
                const Text('Transfer Money', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Recipient Phone', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+250 788 123 456', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 16),
            const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter amount', suffixText: 'RWF', prefixIcon: Icon(Icons.money)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSuccessDialog('Transfer completed successfully!');
                },
                child: const Text('Transfer'),
              ),
            ),
          ],
        ),
      ),
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
