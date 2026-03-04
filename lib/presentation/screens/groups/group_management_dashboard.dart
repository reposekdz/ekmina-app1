import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';

class GroupManagementDashboard extends ConsumerStatefulWidget {
  final String groupId;
  final String userId;
  const GroupManagementDashboard({super.key, required this.groupId, required this.userId});

  @override
  ConsumerState<GroupManagementDashboard> createState() => _GroupManagementDashboardState();
}

class _GroupManagementDashboardState extends ConsumerState<GroupManagementDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _groupData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getFounderDashboard(widget.groupId, widget.userId);
      if (mounted) {
        setState(() {
          _groupData = response;
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gucunga Itsinda')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF00A86B))),
      );
    }

    final group = _groupData?['group'] ?? {};
    final stats = _groupData?['stats'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(group['name'] ?? 'Gucunga Itsinda', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Ibisobanuro'),
            Tab(icon: Icon(Icons.people), text: 'Abanyamuryango'),
            Tab(icon: Icon(Icons.settings), text: 'Amabwiriza'),
            Tab(icon: Icon(Icons.analytics), text: 'Raporo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(stats, group),
          _buildMembersTab(),
          _buildSettingsTab(group),
          _buildReportsTab(stats),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> stats, Map<String, dynamic> group) {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard('Abanyamuryango', '${stats['totalMembers'] ?? 0}', Icons.people, Colors.blue),
          _buildStatCard('Imigabane yose', Formatters.formatCurrency((stats['totalShares'] ?? 0).toDouble()), Icons.account_balance, Colors.green),
          _buildStatCard('Amafaranga yose', Formatters.formatCurrency((stats['totalDeposits'] ?? 0).toDouble()), Icons.savings, Colors.orange),
          _buildStatCard('Ayasigaye (Escrow)', Formatters.formatCurrency((group['escrowBalance'] ?? 0).toDouble()), Icons.lock, Colors.purple),
          const SizedBox(height: 24),
          const Text('Ibikorwa biheruka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        trailing: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  Widget _buildActivityList() {
    final activities = _groupData?['activities'] as List? ?? [];
    if (activities.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Nta bikorwa bihari', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: activities.map((activity) => Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _getActivityColor(activity['type']).withOpacity(0.1),
                child: Icon(_getActivityIcon(activity['type']), color: _getActivityColor(activity['type']), size: 20),
              ),
              title: Text(activity['description'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text(Formatters.formatDateTime(DateTime.parse(activity['createdAt'])), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
            if (activities.last != activity) const Divider(height: 1),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildMembersTab() {
    final members = _groupData?['members'] as List? ?? [];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/groups/${widget.groupId}/add-member?userId=${widget.userId}'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ongeramo'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B), foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showInviteCode(group: _groupData?['group']),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Invite Code'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: members.isEmpty
            ? const Center(child: Text('Nta banyamuryango barimo'))
            : ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member['avatar'] != null ? NetworkImage(member['avatar']) : null,
                      child: member['avatar'] == null ? Text(member['name']?[0] ?? 'U') : null,
                    ),
                    title: Text(member['name'] ?? 'Umuryango', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Imigabane: ${Formatters.formatCurrency((member['totalShares'] ?? 0).toDouble())}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'manage', child: Text('Gucunga')),
                        const PopupMenuItem(value: 'remove', child: Text('Kuvana mu itsinda', style: TextStyle(color: Colors.red))),
                      ],
                      onSelected: (val) => _handleMemberAction(val.toString(), member),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(Map<String, dynamic> group) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingSection('Amashoramari n\'Imari', [
          _buildSettingItem('Agaciro k\'umugabane', Formatters.formatCurrency((group['shareValue'] ?? 0).toDouble()), Icons.money, () => _updateGroupSetting('shareValue', group['shareValue'])),
          _buildSettingItem('Amafaranga yo kwinjira', Formatters.formatCurrency((group['joinFee'] ?? 0).toDouble()), Icons.payment, () => _updateGroupSetting('joinFee', group['joinFee'])),
          _buildSettingItem('Inyungu ku nguzanyo', '${(group['loanInterestRate'] ?? 0) * 100}%', Icons.percent, () => _updateGroupSetting('loanInterestRate', group['loanInterestRate'])),
        ]),
        const SizedBox(height: 16),
        _buildSettingSection('Ingengabihe y\'Imisanzu', [
          _buildSettingItem('Inshuro', group['contributionFrequency'] ?? 'Weekly', Icons.calendar_today, () => _updateGroupSetting('contributionFrequency', group['contributionFrequency'])),
          _buildSettingItem('Umunsi wo gukusanya', group['collectionDay'] ?? 'Sunday', Icons.event, () => _updateGroupSetting('collectionDay', group['collectionDay'])),
        ]),
        const SizedBox(height: 16),
        _buildSettingSection('Ibihano', [
          _buildSettingItem('Agaciro k\'igihano', Formatters.formatCurrency((group['penaltyAmount'] ?? 0).toDouble()), Icons.warning_amber, () => _updateGroupSetting('penaltyAmount', group['penaltyAmount'])),
        ]),
      ],
    );
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00A86B))),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildReportsTab(Map<String, dynamic> stats) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Inyandiko y\'Imari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                _buildReportRow('Imisanzu Yose', Formatters.formatCurrency((stats['totalContributions'] ?? 0).toDouble())),
                _buildReportRow('Inguzanyo Zishyuwe', Formatters.formatCurrency((stats['totalLoansDisbursed'] ?? 0).toDouble())),
                _buildReportRow('Ibihano Byishyuwe', Formatters.formatCurrency((stats['totalPenaltiesCollected'] ?? 0).toDouble())),
                _buildReportRow('Inyungu Yose', Formatters.formatCurrency((stats['totalInterestEarned'] ?? 0).toDouble())),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ayasigaye mu kigega', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(Formatters.formatCurrency((stats['availableCapital'] ?? 0).toDouble()), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A86B), fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _exportReport,
            icon: const Icon(Icons.file_download),
            label: const Text('Kuramo Raporo (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ),
      ],
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'CONTRIBUTION': return Icons.payment;
      case 'LOAN_APPLICATION': return Icons.request_quote;
      case 'JOIN_REQUEST': return Icons.person_add;
      default: return Icons.info_outline;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'CONTRIBUTION': return Colors.green;
      case 'LOAN_APPLICATION': return Colors.blue;
      case 'JOIN_REQUEST': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Future<void> _updateGroupSetting(String key, dynamic currentValue) async {
    final controller = TextEditingController(text: currentValue.toString());
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hindura $key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          keyboardType: currentValue is num ? TextInputType.number : TextInputType.text,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hagarika')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Emeza')),
        ],
      ),
    );

    if (result == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.manageGroup(widget.groupId, widget.userId, 'update_setting', {
          'key': key,
          'value': currentValue is num ? num.parse(controller.text) : controller.text,
        });
        _loadDashboard();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
      }
    }
  }

  void _handleMemberAction(String action, dynamic member) async {
    if (action == 'remove') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kuvana mu itsinda'),
          content: Text('Uremeza ko ukuye ${member['name']} mu itsinda?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hagarika')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Emeza'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          final api = ref.read(apiClientProvider);
          await api.manageGroup(widget.groupId, widget.userId, 'remove_member', {'memberId': member['id']});
          _loadDashboard();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showInviteCode({dynamic group}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kwinjira mu itsinda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
              child: Text(group?['inviteCode'] ?? '-------', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
            ),
            const SizedBox(height: 24),
            const Text('Oherereza iyi code abandi kugira ngo binjire mu itsinda ryawe.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.share), label: const Text('Sangira Code'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B))),
            ),
          ],
        ),
      ),
    );
  }

  void _exportReport() {
    // PDF Export logic would go here
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Raporo iri gutegurwa...')));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
