import 'package:flutter/material.dart';
import 'loan_application_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String location;
  final int memberCount;
  final double totalBalance;
  final double userBalance;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.location,
    required this.memberCount,
    required this.totalBalance,
    required this.userBalance,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildGroupHeader()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverFillRemaining(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00A86B), Color(0xFF00D68F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(widget.location, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(width: 16),
                      const Icon(Icons.people, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text('${widget.memberCount} members', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.share), onPressed: _shareGroup),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: _showGroupMenu),
      ],
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total Balance', '${widget.totalBalance.toStringAsFixed(0)} RWF', Icons.account_balance),
              ),
              Container(width: 1, height: 50, color: Colors.grey[300]),
              Expanded(
                child: _buildStatItem('Your Balance', '${widget.userBalance.toStringAsFixed(0)} RWF', Icons.wallet),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem('Your Shares', '120', Icons.pie_chart)),
              Container(width: 1, height: 50, color: Colors.grey[300]),
              Expanded(child: _buildStatItem('Share Value', '1,000 RWF', Icons.attach_money)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00A86B), size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildActionButton('Deposit', Icons.add_circle, const Color(0xFF00A86B), _deposit)),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton('Withdraw', Icons.remove_circle, const Color(0xFFFFB800), _withdraw)),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton('Loan', Icons.request_quote, const Color(0xFF0066CC), _requestLoan)),
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
      margin: const EdgeInsets.all(16),
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
          Tab(text: 'Members'),
          Tab(text: 'Transactions'),
          Tab(text: 'About'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildMembersList(),
        _buildTransactionsList(),
        _buildAboutTab(),
      ],
    );
  }

  Widget _buildMembersList() {
    final members = [
      {'name': 'Jean Mukama', 'role': 'Admin', 'shares': 120, 'balance': '120,000 RWF', 'avatar': 'JM'},
      {'name': 'Marie Uwase', 'role': 'Admin', 'shares': 95, 'balance': '95,000 RWF', 'avatar': 'MU'},
      {'name': 'Patrick Niyonzima', 'role': 'Member', 'shares': 150, 'balance': '150,000 RWF', 'avatar': 'PN'},
      {'name': 'Grace Mutoni', 'role': 'Member', 'shares': 80, 'balance': '80,000 RWF', 'avatar': 'GM'},
      {'name': 'Eric Habimana', 'role': 'Member', 'shares': 110, 'balance': '110,000 RWF', 'avatar': 'EH'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildMemberItem(
          member['name'] as String,
          member['role'] as String,
          member['shares'] as int,
          member['balance'] as String,
          member['avatar'] as String,
        );
      },
    );
  }

  Widget _buildMemberItem(String name, String role, int shares, String balance, String avatar) {
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
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF00A86B),
            child: Text(avatar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (role == 'Admin') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('$shares shares • $balance', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final transactions = [
      {'type': 'Deposit', 'member': 'Jean Mukama', 'amount': '5,000', 'date': 'Jan 15, 2026', 'isCredit': true},
      {'type': 'Loan Disbursement', 'member': 'Marie Uwase', 'amount': '50,000', 'date': 'Jan 14, 2026', 'isCredit': false},
      {'type': 'Deposit', 'member': 'Patrick Niyonzima', 'amount': '5,000', 'date': 'Jan 13, 2026', 'isCredit': true},
      {'type': 'Penalty', 'member': 'Grace Mutoni', 'amount': '500', 'date': 'Jan 12, 2026', 'isCredit': true},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _buildTransactionItem(
          tx['type'] as String,
          tx['member'] as String,
          tx['amount'] as String,
          tx['date'] as String,
          tx['isCredit'] as bool,
        );
      },
    );
  }

  Widget _buildTransactionItem(String type, String member, String amount, String date, bool isCredit) {
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
                Text(member, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('Group Information', [
          {'label': 'Group ID', 'value': widget.groupId},
          {'label': 'Created', 'value': 'Dec 1, 2025'},
          {'label': 'Type', 'value': 'Savings & Loans'},
          {'label': 'Status', 'value': 'Active'},
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Financial Rules', [
          {'label': 'Share Value', 'value': '1,000 RWF'},
          {'label': 'Min Shares', 'value': '10'},
          {'label': 'Max Loan Multiplier', 'value': '3x shares'},
          {'label': 'Interest Rate', 'value': '10%'},
          {'label': 'Late Payment Penalty', 'value': '5%'},
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Meeting Schedule', [
          {'label': 'Frequency', 'value': 'Monthly'},
          {'label': 'Next Meeting', 'value': 'Jan 20, 2026'},
          {'label': 'Time', 'value': '2:00 PM'},
          {'label': 'Location', 'value': widget.location},
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Description', [
          {'label': '', 'value': 'A community savings group focused on financial empowerment and mutual support.'},
        ]),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...items.map((item) {
            if (item['label']!.isEmpty) {
              return Text(item['value']!, style: TextStyle(color: Colors.grey[600]));
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['label']!, style: TextStyle(color: Colors.grey[600])),
                  Text(item['value']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _deposit() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening deposit form...')));
  }

  void _withdraw() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening withdrawal form...')));
  }

  void _requestLoan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanApplicationScreen(
          groupId: widget.groupId,
          groupName: widget.groupName,
          totalShares: 120,
          shareValue: 1000,
          interestRate: 10,
        ),
      ),
    );
  }

  void _shareGroup() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing group...')));
  }

  void _showGroupMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF00A86B)),
              title: const Text('Edit Group'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Color(0xFF00A86B)),
              title: const Text('Invite Members'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF00A86B)),
              title: const Text('Group Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Leave Group', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
