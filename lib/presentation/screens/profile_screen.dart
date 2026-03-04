import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../routes/app_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final storage = SecureStorageService();
      final userId = await storage.getUserId();
      if (userId == null) return;

      final api = ref.read(apiClientProvider);
      final profileData = await api.getUserProfile(userId);
      final walletData = await api.getWallet(userId);
      final groupsData = await api.getGroups(userId);

      if (mounted) {
        setState(() {
          _userData = profileData['user'];
          _stats = {
            'groups': (groupsData['groups'] as List?)?.length ?? 0,
            'balance': (walletData['wallet']?['balance'] ?? 0).toDouble(),
            'shares': (walletData['wallet']?['totalShares'] ?? 0).toDouble(),
          };
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

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gusohoka'),
        content: const Text('Emeza ko ushaka gusohoka muri konti yawe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yego, sohoka'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = SecureStorageService();
      await storage.clearAuthData();
      ref.read(authStateProvider.notifier).state = false;
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Konti')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatsCard(),
                const SizedBox(height: 24),
                _buildSection('Konti', [
                  _buildMenuItem(Icons.account_balance_wallet_outlined, 'Ijakanshyi ryanjye', 'Cunga amafaranga yawe', () => context.push('/wallet')),
                  _buildMenuItem(Icons.history, 'Amateka y\'ibyakozwe', 'Reba ibikorwa byose', () => context.push('/transactions')),
                  _buildMenuItem(Icons.credit_card, 'Uburyo bwo kwishyura', 'Cunga uburyo ukoresha', () {}),
                ]),
                const SizedBox(height: 16),
                _buildSection('Amatsinda', [
                  _buildMenuItem(Icons.groups_outlined, 'Amatsinda yanjye', '${_stats?['groups'] ?? 0} amatsinda urimo', () => context.push('/groups')),
                  _buildMenuItem(Icons.request_quote_outlined, 'Inguzanyo zanjye', 'Reba inguzanyo ufite', () => context.push('/loans')),
                  _buildMenuItem(Icons.people_outline, 'Ubutumire', 'Ubutumire butararebwa', () {}),
                ]),
                const SizedBox(height: 16),
                _buildSection('Igenamiterere', [
                  _buildMenuItem(Icons.person_outline, 'Umwirondoro', 'Hindura amakuru yawe', () {}),
                  _buildMenuItem(Icons.lock_outline, 'Umutekano', 'PIN n\'uburyo bwo gufungura', () {}),
                  _buildMenuItem(Icons.notifications_outlined, 'Integuza', 'Igenamiterere ry\'integuza', () => context.push('/notifications')),
                  _buildMenuItem(Icons.language, 'Ururimi', 'Ikinyarwanda', () => context.push('/settings')),
                ]),
                const SizedBox(height: 16),
                _buildSection('Ubufasha', [
                  _buildMenuItem(Icons.help_outline, 'Ubufasha', 'Ibibazo bikunze kubazwa', () {}),
                  _buildMenuItem(Icons.info_outline, 'Ibijyanye natwe', 'Verisiyo 2.1.0', () {}),
                ]),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('SOHOKA', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240.0,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Text(_userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              ),
              const SizedBox(height: 12),
              Text(_userData?['name'] ?? 'Umukoresha',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(_userData?['phone'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Amatsinda', '${_stats?['groups'] ?? 0}', Icons.groups, AppTheme.accentBlue),
          _buildStatItem('Imigabane', Formatters.formatCompactNumber(_stats?['shares'] ?? 0), Icons.pie_chart, AppTheme.secondaryGold),
          _buildStatItem('Ijakanshyi', Formatters.formatCompactNumber(_stats?['balance'] ?? 0), Icons.account_balance_wallet, AppTheme.primaryGreen),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 8, top: 16),
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
