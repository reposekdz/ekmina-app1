import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:go_router/go_router.dart';
import '../../../data/remote/api_client.dart';
import '../../../data/local/hive_service.dart';

class EnhancedHomeScreen extends ConsumerStatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  ConsumerState<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends ConsumerState<EnhancedHomeScreen> {
  final _apiClient = ApiClient();
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _groups = [];
  List<dynamic> _transactions = [];
  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final user = HiveService.getUser();
      _userId = user?['id'];
      
      if (_userId != null) {
        final results = await Future.wait([
          _apiClient.get('/dashboard', queryParameters: {'userId': _userId}),
          _apiClient.getGroups(_userId!),
          _apiClient.getTransactions(userId: _userId),
          _apiClient.getWallet(_userId!),
        ]);
        final dashboard = results[0] as dynamic;
        final groups = results[1];
        final transactions = results[2];
        final wallet = results[3];

        if (mounted) {
          setState(() {
            _dashboardData = {...(dashboard.data as Map<String, dynamic>), 'wallet': (wallet as Map<String, dynamic>)['wallet']};
            _groups = ((groups as Map<String, dynamic>)['groups'] as List?) ?? [];
            _transactions = ((transactions as Map<String, dynamic>)['transactions'] as List?) ?? [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Kimina Rwanda'),
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
              if (_dashboardData?['stats']?['pendingContributions'] > 0)
                Positioned(right: 8, top: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
            ],
          ),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildMyGroups(),
              const SizedBox(height: 16),
              _buildRecentTransactions(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/create'),
        icon: const Icon(Icons.add),
        label: const Text('Kora itsinda'),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _dashboardData?['wallet']?['balance'] ?? 0.0;
    final shares = _dashboardData?['stats']?['totalShares'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00C853)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet yawe', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('${balance.toStringAsFixed(0)} RWF', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceItem('Imigabane', '${shares.toStringAsFixed(0)} RWF', Icons.pie_chart),
              _buildBalanceItem('Amatsinda', '${_dashboardData?['stats']?['totalGroups'] ?? 0}', Icons.group),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(Icons.add_circle_outline, 'Shyiramo', () => context.push('/wallet')),
              _buildQuickActionButton(Icons.send, 'Ohereza', () => context.push('/wallet/send')),
              _buildQuickActionButton(Icons.trending_up, 'Ishoramari', () => context.push('/investment')),
              _buildQuickActionButton(Icons.request_quote, 'Inguzanyo', () => context.push('/loans')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(Icons.group_add, 'Injira', () => context.push('/groups/public')),
              _buildQuickActionButton(Icons.search, 'Shakisha', () => context.push('/search')),
              _buildQuickActionButton(Icons.forum, 'Umuryango', () => context.push('/community')),
              _buildQuickActionButton(Icons.analytics, 'Raporo', () => context.push('/reports')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: const Color(0xFF00A86B).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF00A86B), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMyGroups() {
    if (_groups.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amatsinda yawe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => context.push('/groups'), child: const Text('Reba byose')),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              return GestureDetector(
                onTap: () => context.push('/groups/${group['id']}'),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00A86B), Color(0xFF00C853)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.people, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text('${group['_count']?['members'] ?? 0} abanyamuryango', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${group['escrowBalance']?.toStringAsFixed(0) ?? '0'} RWF', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    if (_transactions.isEmpty) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ibyakozwe vuba', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => context.push('/transactions'), child: const Text('Reba byose')),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length > 5 ? 5 : _transactions.length,
            itemBuilder: (context, index) {
              final tx = _transactions[index];
              final isDeposit = tx['type'] == 'CONTRIBUTION' || tx['type'] == 'DEPOSIT';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDeposit ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    child: Icon(isDeposit ? Icons.arrow_downward : Icons.arrow_upward, color: isDeposit ? Colors.green : Colors.orange),
                  ),
                  title: Text(tx['type']),
                  subtitle: Text(tx['group']?['name'] ?? 'Wallet'),
                  trailing: Text('${tx['amount'].toStringAsFixed(0)} RWF', style: TextStyle(fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : Colors.orange)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
