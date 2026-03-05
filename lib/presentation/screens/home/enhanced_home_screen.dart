import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../data/local/hive_service.dart';
import '../../../core/theme/app_theme.dart';

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
        
        if (mounted) {
          setState(() {
            _dashboardData = {...(results[0] as Map<String, dynamic>), 'wallet': (results[3] as Map<String, dynamic>)['wallet']};
            _groups = ((results[1] as Map<String, dynamic>)['groups'] as List?) ?? [];
            _transactions = ((results[2] as Map<String, dynamic>)['transactions'] as List?) ?? [];
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _loading 
              ? _buildLoadingState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      _buildBalanceCard().animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      _buildQuickActions().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      _buildMyGroups().animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                      const SizedBox(height: 24),
                      _buildRecentTransactions().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final user = HiveService.getUser();
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        centerTitle: false,
        title: Text(
          'Muraho, ${user?['name']?.split(' ')[0] ?? 'Nshuti'}!',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.bell),
          onPressed: () => context.push('/notifications'),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const Center(
              child: Icon(LucideIcons.user, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 100),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _dashboardData?['wallet']?['balance'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.wallet, color: Colors.white.withOpacity(0.8), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Wallet yawe',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${balance.toStringAsFixed(0)} RWF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildBalanceStat(LucideIcons.trendingUp, 'Inyungu', '+12%'),
                    const SizedBox(width: 24),
                    _buildBalanceStat(LucideIcons.users, 'Amatsinda', '${_dashboardData?['stats']?['totalGroups'] ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 10,
        children: [
          _buildActionItem(LucideIcons.plusCircle, 'Emeza', AppTheme.primaryBlue, () => context.push('/wallet')),
          _buildActionItem(LucideIcons.send, 'Ohereza', AppTheme.accentIndigo, () => context.push('/wallet/send')),
          _buildActionItem(LucideIcons.trendingUp, 'Ishoramari', AppTheme.primaryGreen, () => context.push('/investment')),
          _buildActionItem(LucideIcons.landmark, 'Inguzanyo', Colors.orange, () => context.push('/loans')),
          _buildActionItem(LucideIcons.users, 'Injira', AppTheme.accentViolet, () => context.push('/groups/public')),
          _buildActionItem(LucideIcons.search, 'Shakisha', Colors.blueGrey, () => context.push('/search')),
          _buildActionItem(LucideIcons.messageSquare, 'Chat', Colors.teal, () => context.push('/community')),
          _buildActionItem(LucideIcons.barChart3, 'Raporo', AppTheme.accentRose, () => context.push('/reports')),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMyGroups() {
    if (_groups.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amatsinda yawe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/groups'),
                child: const Text('Reba yose'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/groups/${group['id']}'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.surface.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.users, color: AppTheme.primaryBlue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  group['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            'Escrow Balance',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${group['escrowBalance']?.toStringAsFixed(0) ?? '0'} RWF',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ibyakozwe vuba',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/transactions'),
                child: const Text('Reba byose'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._transactions.take(5).map((tx) {
            final isDeposit = tx['type'] == 'CONTRIBUTION' || tx['type'] == 'DEPOSIT';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDeposit ? Colors.green : Colors.orange).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDeposit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                    color: isDeposit ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(
                  tx['type'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  tx['group']?['name'] ?? 'Wallet Henzo',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Text(
                  '${isDeposit ? "+" : "-"}${tx['amount'].toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDeposit ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
