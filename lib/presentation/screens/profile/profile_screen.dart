import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../routes/app_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _stats;
  List<dynamic> _recentActivity = [];
  bool _loading = true;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
    _checkBiometric();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final storage = SecureStorageService();
      final userId = await storage.getUserId();
      if (userId == null) {
        if (mounted) context.go('/login');
        return;
      }

      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.getWallet(userId),
        api.getGroups(userId),
        api.getTransactions(userId: userId),
        api.getLoans(membershipId: userId),
      ]);
      
      final phone = await storage.getUserPhone();

      if (mounted) {
        setState(() {
          _userData = {
            'userId': userId,
            'phone': phone,
            'balance': (results[0]['wallet']?['balance'] ?? 0).toDouble(),
            'groupCount': (results[1]['groups'] as List?)?.length ?? 0,
          };
          _stats = {
            'totalDeposits': (results[2]['transactions'] as List?)?.where((t) => t['type'] == 'DEPOSIT' || t['type'] == 'CONTRIBUTION').fold(0.0, (sum, t) => sum + (t['amount'] ?? 0)) ?? 0,
            'totalWithdrawals': (results[2]['transactions'] as List?)?.where((t) => t['type'] == 'WITHDRAWAL').fold(0.0, (sum, t) => sum + (t['amount'] ?? 0)) ?? 0,
            'activeLoans': (results[3]['loans'] as List?)?.where((l) => l['status'] == 'ACTIVE').length ?? 0,
            'totalLoans': (results[3]['loans'] as List?)?.fold(0.0, (sum, l) => sum + (l['amount'] ?? 0)) ?? 0,
          };
          _recentActivity = (results[2]['transactions'] as List?)?.take(10).toList() ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _checkBiometric() async {
    final storage = SecureStorageService();
    final enabled = await storage.isBiometricEnabled();
    setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleBiometric(bool value) async {
    final biometric = BiometricService();
    if (value) {
      final canAuth = await biometric.canCheckBiometrics();
      if (!canAuth) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intoki/Isura ntiboneka')));
        return;
      }
      final authenticated = await biometric.authenticateForLogin();
      if (authenticated) {
        await SecureStorageService().setBiometricEnabled(true);
        setState(() => _biometricEnabled = true);
      }
    } else {
      await SecureStorageService().setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(),
                  stretchModes: const [StretchMode.zoomBackground],
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Amakuru'),
                    Tab(text: 'Imibare'),
                    Tab(text: 'Ibikorwa'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildStatsTab(),
                _buildActivityTab(),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05)),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: const Icon(LucideIcons.user, size: 50, color: AppTheme.primaryBlue),
                ),
              ).animate().scale().fadeIn(),
              const SizedBox(height: 16),
              Text(
                Formatters.formatPhone(_userData?['phone'] ?? ''),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Umunyamuryango wa E-Kimina',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Umubike wawe'),
        const SizedBox(height: 12),
        _buildStatCard(
          'Balance yose', 
          Formatters.formatCurrency(_userData?['balance'] ?? 0), 
          LucideIcons.wallet, 
          AppTheme.primaryBlue,
        ),
        _buildStatCard(
          'Amatsinda urimo', 
          '${_userData?['groupCount'] ?? 0} Amatsinda', 
          LucideIcons.users, 
          AppTheme.primaryYellow,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Igenamiterere'),
        const SizedBox(height: 12),
        _buildMenuCard([
          _buildMenuItem(LucideIcons.user, 'Hindura Amazina', () {}),
          _buildMenuItem(LucideIcons.lock, 'Hindura Ijambo ry\'ibanga', () {}),
          _buildMenuItem(LucideIcons.shieldCheck, 'PIN ya Wallet', () {}),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader('Umutekano'),
        const SizedBox(height: 12),
        _buildMenuCard([
          SwitchListTile(
            value: _biometricEnabled,
            onChanged: _toggleBiometric,
            secondary: const Icon(LucideIcons.fingerprint, color: AppTheme.primaryBlue),
            title: const Text('Intoki / Isura', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader('Ibindi'),
        const SizedBox(height: 12),
        _buildMenuCard([
          _buildMenuItem(LucideIcons.helpCircle, 'Ubufasha', () {}),
          _buildMenuItem(LucideIcons.info, 'Amategeko n\'amabwiriza', () {}),
          _buildMenuItem(LucideIcons.logOut, 'Sohoka muri App', _logout, color: Colors.red),
        ]),
        const SizedBox(height: 100),
      ],
    ).animate().fadeIn();
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.primaryBlue, size: 22),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatCard('Ayashyizweho yose', Formatters.formatCurrency(_stats?['totalDeposits'] ?? 0), LucideIcons.trendingUp, Colors.green),
        _buildStatCard('Ayakuweho yose', Formatters.formatCurrency(_stats?['totalWithdrawals'] ?? 0), LucideIcons.trendingDown, Colors.orange),
        _buildStatCard('Inguzanyo Zose', Formatters.formatCurrency(_stats?['totalLoans'] ?? 0), LucideIcons.landmark, AppTheme.accentIndigo),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(LucideIcons.award, size: 48, color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              const Text('Incamake y\'ubwizigame', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'Urakataje mu kubika no kugurizanya! Komeza gutya ubashe kwiteza imbere hamwe na E-Kimina.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildActivityTab() {
    if (_recentActivity.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clock, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Nta bikorwa bihari', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _recentActivity.length,
      itemBuilder: (context, index) {
        final activity = _recentActivity[index];
        final isDeposit = activity['type'] == 'DEPOSIT' || activity['type'] == 'CONTRIBUTION';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isDeposit ? Colors.green : Colors.orange).withOpacity(0.1),
              child: Icon(
                isDeposit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                color: isDeposit ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            title: Text(activity['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(Formatters.formatDate(DateTime.parse(activity['createdAt'])), style: const TextStyle(fontSize: 12)),
            trailing: Text(
              Formatters.formatCurrency(activity['amount'].toDouble()),
              style: TextStyle(fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : Colors.orange),
            ),
          ),
        );
      },
    ).animate().fadeIn();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gusohoka'),
        content: const Text('Uremeza ko ushaka gusohoka muri porogaramu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Yego, Sohoka', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SecureStorageService().clearAll();
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
