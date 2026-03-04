import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';
import 'add_member_screen.dart';
import '../contributions/contributions_screen.dart';
import '../meetings/meetings_screen.dart';
import '../announcements/announcements_screen.dart';
import '../dividends/dividends_screen.dart';

class AdvancedFounderDashboard extends ConsumerStatefulWidget {
  final String groupId;
  final String userId;
  const AdvancedFounderDashboard({super.key, required this.groupId, required this.userId});

  @override
  ConsumerState<AdvancedFounderDashboard> createState() => _AdvancedFounderDashboardState();
}

class _AdvancedFounderDashboardState extends ConsumerState<AdvancedFounderDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dashboardData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getFounderDashboard(widget.groupId, widget.userId);
      if (mounted) {
        setState(() {
          _dashboardData = response;
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

  Future<void> _approveJoinRequest(String requestId, bool approve) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.approveJoinRequest(requestId, approve);
      _loadDashboard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Ubusabe bwemejwe!' : 'Ubusabe bwanzwe!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Founder Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final group = _dashboardData!['group'];

    return Scaffold(
      appBar: AppBar(
        title: Text(group['name'] ?? 'Dashboard', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDashboard)],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Ibanze'),
            Tab(text: 'Abasaba'),
            Tab(text: 'Abanyamuryango'),
            Tab(text: 'Imari'),
            Tab(text: 'Igenamiterere'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildJoinRequestsTab(),
          _buildMembersTab(),
          _buildFinancialTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMemberScreen(groupId: widget.groupId, userId: widget.userId)),
          );
          if (result == true) _loadDashboard();
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Ohereza ubutumire'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _dashboardData!['stats'];
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMainBalanceCard(stats['escrowBalance'] ?? 0),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Abanyamuryango', '${stats['totalMembers']}', Icons.people, AppTheme.accentBlue),
              _buildStatCard('Abasaba kwinjira', '${stats['pendingRequests']}', Icons.pending_actions, Colors.orange),
              _buildStatCard('Imigabane yose', Formatters.formatCompactNumber(stats['totalShares'] ?? 0), Icons.pie_chart, AppTheme.secondaryGold),
              _buildStatCard('Inguzanyo zikora', '${stats['activeLoans']}', Icons.request_quote, Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Ibikorwa by\'ubuyobozi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildAdminAction('Gushyiraho Inama', Icons.event, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => MeetingsScreen(groupId: widget.groupId, userId: widget.userId, isAdmin: true)))),
          _buildAdminAction('Tanga Itangazo', Icons.campaign, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => AnnouncementsScreen(groupId: widget.groupId, userId: widget.userId, isAdmin: true)))),
          _buildAdminAction('Gabana Inyungu', Icons.account_balance_wallet, AppTheme.primaryGreen, () => Navigator.push(context, MaterialPageRoute(builder: (context) => DividendsScreen(groupId: widget.groupId, membershipId: '', userId: widget.userId, isAdmin: true)))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMainBalanceCard(dynamic balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryGreen, Color(0xFF00D68F)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text('Amafaranga yose ari muri Escrow', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(Formatters.formatCurrency(balance.toDouble()),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Aya mafaranga abitswe mu buryo bwizewe kuri Banki.',
            style: TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  Widget _buildJoinRequestsTab() {
    final requests = _dashboardData!['joinRequests'] as List? ?? [];
    if (requests.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person_search, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), const Text('Nta basaba kwinjira bahari')]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final user = request['user'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: AppTheme.primaryGreen.withOpacity(0.1), child: Text(user['name']?[0].toUpperCase() ?? 'U', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold))),
                  title: Text(user['name'] ?? 'Umukoresha', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user['phone'] ?? ''),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => _approveJoinRequest(request['id'], false), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('YAHAKANE'))),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(onPressed: () => _approveJoinRequest(request['id'], true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen), child: const Text('MWEMEZE'))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    final members = _dashboardData!['members'] as List? ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final user = member['user'];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(user['name']?[0].toUpperCase() ?? 'U')),
            title: Text(user['name'] ?? 'Umunyamuryango'),
            subtitle: Text('Imigabane: ${Formatters.formatCurrency(member['totalShares']?.toDouble() ?? 0)}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(member['role'] ?? 'MEMBER', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialTab() {
    final stats = _dashboardData!['stats'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatTile('Amafaranga yashyizweho', stats['totalDeposits'] ?? 0, Icons.arrow_downward, Colors.green),
        _buildStatTile('Inguzanyo zatanzwe', stats['totalLoansGiven'] ?? 0, Icons.arrow_upward, Colors.orange),
        _buildStatTile('Ibihano byakusanyijwe', stats['penaltiesCollected'] ?? 0, Icons.warning_amber, Colors.redAccent),
        _buildStatTile('Inyungu yabonetse', stats['interestEarned'] ?? 0, Icons.trending_up, AppTheme.primaryGreen),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('KURAMO RAPORO Y\'IMARI (PDF)'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, dynamic value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: Text(Formatters.formatCurrency(value.toDouble()), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSettingsTab() {
    final group = _dashboardData!['group'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingRow('Izina ry\'itsinda', group['name']),
        _buildSettingRow('Agaciro k\'umugabane', Formatters.formatCurrency(group['shareValue']?.toDouble() ?? 0)),
        _buildSettingRow('Amafaranga yo kwinjira', Formatters.formatCurrency(group['joinFee']?.toDouble() ?? 0)),
        _buildSettingRow('Igihe cyo gutanga', group['contributionFrequency'] ?? 'WEEKLY'),
        _buildSettingRow('Inyungu ku nguzanyo', '${group['loanInterestRate']}%'),
        _buildSettingRow('Ihano ry\'ubukererwe', Formatters.formatCurrency(group['penaltyAmount']?.toDouble() ?? 0)),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
          child: const Text('HINDURA IGENAMITERERE'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('HAGARIKA ITSINDA'),
        ),
      ],
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
