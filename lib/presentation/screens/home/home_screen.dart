import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentBottomIndex = 0;
  int _carouselIndex = 0;
  List<dynamic> _groups = [];
  List<dynamic> _transactions = [];
  double _totalBalance = 0;
  double _totalShares = 0;
  double _totalLoans = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final storage = SecureStorageService();
      final userId = await storage.getUserId();
      if (userId == null) {
        if (mounted) context.go('/login');
        return;
      }

      final api = ref.read(apiClientProvider);
      final groupsData = await api.getGroups(userId);
      final transactionsData = await api.getTransactions(userId: userId);
      final walletData = await api.getWallet(userId);

      if (mounted) {
        setState(() {
          _groups = groupsData['groups'] ?? [];
          _transactions = (transactionsData['transactions'] ?? []).take(5).toList();
          _totalBalance = (walletData['balance'] ?? 0).toDouble();
          _totalShares = (walletData['totalShares'] ?? 0).toDouble();
          _totalLoans = (walletData['totalLoans'] ?? 0).toDouble();
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
        title: const Text('E-Kimina Rwanda', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(),
                    const SizedBox(height: 16),
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildMyGroups(),
                    const SizedBox(height: 24),
                    _buildRecentTransactions(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _currentBottomIndex) return;
          setState(() => _currentBottomIndex = index);
          switch (index) {
            case 0: break;
            case 1: context.push('/groups'); break;
            case 2: context.push('/wallet'); break;
            case 3: context.push('/loans'); break;
            case 4: context.push('/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Ahabanza'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Amatsinda'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Ijakanshyi'),
          BottomNavigationBarItem(icon: Icon(Icons.request_quote_outlined), activeIcon: Icon(Icons.request_quote), label: 'Inguzanyo'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Konti'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/create'),
        icon: const Icon(Icons.add),
        label: const Text('Kurema itsinda'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildHeroSection() {
    return FlutterCarousel(
      options: CarouselOptions(
        height: 160.0,
        viewportFraction: 0.9,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        onPageChanged: (index, reason) => setState(() => _carouselIndex = index),
      ),
      items: [
        _buildHeroItem('Ikaze kuri E-Kimina', 'Bika, guza, kandi utere imbere hamwe n\'abandi.', Icons.account_balance, AppTheme.primaryGreen),
        _buildHeroItem('Inguzanyo Zihuse', 'Saba inguzanyo mu matsinda yawe mu kanya gato.', Icons.speed, AppTheme.accentBlue),
        _buildHeroItem('Umutekano Wizewe', 'Amafaranga yawe arinzwe n\'ikoranabuhanga rigezweho.', Icons.security, AppTheme.secondaryGold),
      ],
    );
  }

  Widget _buildHeroItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Icon(icon, size: 60, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 8,
        shadowColor: AppTheme.primaryGreen.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amafaranga yose hamwe', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const Icon(Icons.account_balance_wallet, color: AppTheme.primaryGreen),
                ],
              ),
              const SizedBox(height: 8),
              Text(Formatters.formatCurrency(_totalBalance),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBalanceDetail('Imigabane', _totalShares, Icons.pie_chart, AppTheme.accentBlue),
                  _buildBalanceDetail('Inguzanyo', _totalLoans, Icons.trending_down, Colors.redAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceDetail(String label, double value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(Formatters.formatCurrency(value), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ibikorwa byihuse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickActionButton(Icons.add_circle_outline, 'Eshyuza', AppTheme.primaryGreen, () => context.push('/wallet')),
              _buildQuickActionButton(Icons.request_quote, 'Saba', AppTheme.accentBlue, () => context.push('/loans/request')),
              _buildQuickActionButton(Icons.group_add, 'Rema', AppTheme.secondaryGold, () => context.push('/groups/create')),
              _buildQuickActionButton(Icons.history, 'Amateka', AppTheme.warningOrange, () => context.push('/transactions')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMyGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amatsinda yanjye', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => context.push('/groups'), child: const Text('Byose')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _groups.isEmpty
          ? _buildEmptyGroups()
          : SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return _buildGroupCard(group);
                },
              ),
            ),
      ],
    );
  }

  Widget _buildEmptyGroups() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.group_off_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Nta matsinda urabamo', style: TextStyle(color: Colors.grey[600])),
            TextButton(onPressed: () => context.push('/groups/create'), child: const Text('Rema itsinda rya mbere')),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(dynamic group) {
    return GestureDetector(
      onTap: () => context.push('/groups/${group['id']}'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group['name'] ?? 'Itsinda',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.people, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text('${group['memberCount'] ?? 0} abanyamuryango', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(Formatters.formatCurrency((group['escrowBalance'] ?? 0).toDouble()),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ibikorwa byashize', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => context.push('/transactions'), child: const Text('Byose')),
            ],
          ),
          const SizedBox(height: 8),
          _transactions.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Nta bikorwa urakora', style: TextStyle(color: Colors.grey[600]))))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  final isInflow = tx['type'] == 'DEPOSIT' || tx['type'] == 'CONTRIBUTION' || tx['type'] == 'LOAN_DISBURSEMENT';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isInflow ? AppTheme.successGreen.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(isInflow ? Icons.add : Icons.remove, color: isInflow ? AppTheme.successGreen : Colors.redAccent),
                      ),
                      title: Text(tx['description'] ?? tx['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(Formatters.formatDateTime(DateTime.parse(tx['createdAt'])), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      trailing: Text(Formatters.formatCurrency((tx['amount'] ?? 0).toDouble()),
                        style: TextStyle(fontWeight: FontWeight.bold, color: isInflow ? AppTheme.successGreen : Colors.redAccent)),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}
