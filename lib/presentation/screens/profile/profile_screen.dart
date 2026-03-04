import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      final wallet = await api.getWallet(userId);
      final groups = await api.getGroups(userId);
      final transactions = await api.getTransactions(userId: userId);
      final loans = await api.getLoans(membershipId: userId);
      final phone = await storage.getUserPhone();

      if (mounted) {
        setState(() {
          _userData = {
            'userId': userId,
            'phone': phone,
            'balance': (wallet['wallet']?['balance'] ?? 0).toDouble(),
            'groupCount': (groups['groups'] as List?)?.length ?? 0,
          };
          _stats = {
            'totalDeposits': (transactions['transactions'] as List?)?.where((t) => t['type'] == 'DEPOSIT').fold(0.0, (sum, t) => sum + t['amount']) ?? 0,
            'totalWithdrawals': (transactions['transactions'] as List?)?.where((t) => t['type'] == 'WITHDRAWAL').fold(0.0, (sum, t) => sum + t['amount']) ?? 0,
            'activeLoans': (loans['loans'] as List?)?.where((l) => l['status'] == 'ACTIVE').length ?? 0,
            'totalLoans': (loans['loans'] as List?)?.fold(0.0, (sum, l) => sum + l['amount']) ?? 0,
          };
          _recentActivity = (transactions['transactions'] as List?)?.take(10).toList() ?? [];
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
    if (value) {
      final biometric = BiometricService();
      final canAuth = await biometric.canCheckBiometrics();
      if (!canAuth) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intoki/Isura ntiboneka'), backgroundColor: Colors.red));
        return;
      }
      final authenticated = await biometric.authenticateForLogin();
      if (authenticated) {
        final storage = SecureStorageService();
        await storage.setBiometricEnabled(true);
        setState(() => _biometricEnabled = true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intoki/Isura yashyizweho'), backgroundColor: Colors.green));
      }
    } else {
      final storage = SecureStorageService();
      await storage.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intoki/Isura yavanweho'), backgroundColor: Colors.orange));
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohoka'),
        content: const Text('Uremeza ko ushaka gusohoka?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yego'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = SecureStorageService();
      await storage.clearAll();
      ref.read(authStateProvider.notifier).state = false;
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Umwirondoro')), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Umwirondoro'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProfile)],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Amakuru'), Tab(text: 'Imibare'), Tab(text: 'Ibikorwa')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInfoTab(), _buildStatsTab(), _buildActivityTab()],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)])),
            child: Column(
              children: [
                CircleAvatar(radius: 50, backgroundColor: Colors.white, child: Text(_userData!['phone']?.substring(0, 2) ?? 'U', style: const TextStyle(fontSize: 32, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                Text(Formatters.formatPhone(_userData!['phone'] ?? ''), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text('ID: ${_userData!['userId']?.substring(0, 8)}...', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildStatCard('Amafaranga', Formatters.formatCurrency(_userData!['balance']), Icons.account_balance_wallet, AppTheme.primaryGreen),
          _buildStatCard('Amatsinda', '${_userData!['groupCount']}', Icons.group, AppTheme.accentBlue),
          const SizedBox(height: 16),
          _buildSection('Konti', [
            _buildMenuItem('Hindura amazina', Icons.edit, () => _showEditDialog('name')),
            _buildMenuItem('Hindura nimero', Icons.phone, () => _showEditDialog('phone')),
            _buildMenuItem('Hindura ijambo ryibanga', Icons.lock, () => _showChangePasswordDialog()),
          ]),
          _buildSection('Umutekano', [
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint, color: AppTheme.primaryGreen),
              title: const Text('Intoki/Isura'),
              subtitle: const Text('Koresha intoki cyangwa isura'),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
            _buildMenuItem('PIN ya Wallet', Icons.pin, () => _showChangePinDialog()),
          ]),
          _buildSection('Ubufasha', [
            _buildMenuItem('Ibibazo bikunze kubazwa', Icons.help, () {}),
            _buildMenuItem('Twandikire', Icons.email, () {}),
            _buildMenuItem('Amategeko', Icons.policy, () {}),
            _buildMenuItem('Ibanga', Icons.privacy_tip, () {}),
          ]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.logout),
                label: const Text('Sohoka', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Imibare yawe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildStatRow('Amafaranga yashyizweho', Formatters.formatCurrency(_stats!['totalDeposits']), Icons.arrow_downward, Colors.green),
                const Divider(),
                _buildStatRow('Amafaranga yakuweho', Formatters.formatCurrency(_stats!['totalWithdrawals']), Icons.arrow_upward, Colors.red),
                const Divider(),
                _buildStatRow('Inguzanyo zikoreshwa', '${_stats!['activeLoans']}', Icons.request_quote, AppTheme.accentBlue),
                const Divider(),
                _buildStatRow('Inguzanyo zose', Formatters.formatCurrency(_stats!['totalLoans']), Icons.monetization_on, AppTheme.warningOrange),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Amatsinda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.group, color: AppTheme.primaryGreen),
                  title: const Text('Amatsinda yanjye'),
                  trailing: Text('${_userData!['groupCount']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  onTap: () => context.push('/groups'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    return _recentActivity.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), Text('Nta bikorwa', style: TextStyle(color: Colors.grey[600]))]))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _recentActivity.length,
            itemBuilder: (context, index) {
              final activity = _recentActivity[index];
              final isDeposit = activity['type'] == 'DEPOSIT' || activity['type'] == 'CONTRIBUTION';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDeposit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    child: Icon(isDeposit ? Icons.arrow_downward : Icons.arrow_upward, color: isDeposit ? Colors.green : Colors.red),
                  ),
                  title: Text(activity['description'] ?? activity['type']),
                  subtitle: Text(Formatters.formatDateTime(DateTime.parse(activity['createdAt']))),
                  trailing: Text(Formatters.formatCurrency(activity['amount'].toDouble()), style: TextStyle(fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : Colors.red)),
                ),
              );
            },
          );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey))),
        ...children,
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showEditDialog(String field) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hindura ${field == 'name' ? 'amazina' : 'nimero'}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: field == 'name' ? 'Amazina' : 'Nimero', border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Bika')),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hindura ijambo ryibanga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldController, obscureText: true, decoration: const InputDecoration(labelText: 'Ijambo ryibanga rishaje', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(labelText: 'Ijambo ryibanga rishya', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Hindura')),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hindura PIN'),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(labelText: 'PIN nshya', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Bika')),
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
