import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';
import 'advanced_founder_dashboard.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  Map<String, dynamic>? _groupData;
  Map<String, dynamic>? _membershipData;
  bool _loading = true;
  String? _userId;

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
      _userId = await storage.getUserId();
      if (_userId == null) return;

      final api = ref.read(apiClientProvider);
      final groupResponse = await api.getGroupDetails(widget.groupId, _userId!);
      final membershipResponse = await api.getGroupMembership(widget.groupId, _userId!);
      
      if (mounted) {
        setState(() {
          _groupData = groupResponse['group'];
          _membershipData = membershipResponse['membership'];
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
        appBar: AppBar(title: const Text('Itsinda')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_groupData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ntitubashije kubona itsinda')),
        body: Center(child: ElevatedButton(onPressed: _loadData, child: const Text('Ongera ugerageze'))),
      );
    }

    final isFounder = _groupData!['founderId'] == _userId;
    final isAdmin = (_membershipData?['role'] == 'ADMIN' || isFounder);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isFounder),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildQuickStats(),
                _buildActionGrid(isAdmin),
                _buildGroupInfo(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _membershipData != null ? FloatingActionButton.extended(
        onPressed: () => context.push('/contributions?groupId=${widget.groupId}'),
        icon: const Icon(Icons.payment),
        label: const Text('Kwishyura'),
        backgroundColor: AppTheme.primaryGreen,
      ) : null,
    );
  }

  Widget _buildSliverAppBar(bool isFounder) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      actions: [
        if (isFounder)
          IconButton(
            icon: const Icon(Icons.dashboard_customize),
            onPressed: () => context.push('/groups/${widget.groupId}/dashboard?userId=$_userId'),
            tooltip: 'Founder Dashboard',
          ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(_groupData!['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white,
          shadows: [Shadow(color: Colors.black45, blurRadius: 10)])),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)],
                ),
              ),
            ),
            const Center(child: Icon(Icons.group, size: 80, color: Colors.white24)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Abanyamuryango', '${_groupData!['memberCount']}', Icons.people, AppTheme.accentBlue),
          _buildStatItem('Muri Escrow', Formatters.formatCompactNumber(_groupData!['escrowBalance']), Icons.account_balance, AppTheme.primaryGreen),
          _buildStatItem('Imigabane yawe', Formatters.formatCompactNumber(_membershipData?['totalShares'] ?? 0), Icons.pie_chart, AppTheme.secondaryGold),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      ],
    );
  }

  Widget _buildActionGrid(bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _buildActionItem('Imisanzu', Icons.monetization_on, AppTheme.primaryGreen, () => context.push('/contributions?groupId=${widget.groupId}')),
          _buildActionItem('Inguzanyo', Icons.request_quote, AppTheme.accentBlue, () => context.push('/loans?groupId=${widget.groupId}')),
          _buildActionItem('Abantu', Icons.people_outline, Colors.purple, () => context.push('/groups/${widget.groupId}/members')),
          _buildActionItem('Inama', Icons.event, Colors.orange, () => context.push('/meetings?groupId=${widget.groupId}')),
          _buildActionItem('Amatangazo', Icons.campaign, Colors.redAccent, () => context.push('/announcements?groupId=${widget.groupId}')),
          _buildActionItem('Inyungu', Icons.trending_up, Colors.teal, () => context.push('/dividends?groupId=${widget.groupId}')),
          _buildActionItem('Raporo', Icons.analytics, Colors.indigo, () => context.push('/reports?groupId=${widget.groupId}')),
          _buildActionItem('Ibyakozwe', Icons.history, Colors.blueGrey, () => context.push('/transactions?groupId=${widget.groupId}')),
          if (isAdmin) _buildActionItem('Gucunga', Icons.settings, Colors.grey, () => context.push('/groups/${widget.groupId}/dashboard')),
        ],
      ),
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Amakuru y\'itsinda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoRow('Ibisobanuro', _groupData!['description'] ?? 'Nta bisobanuro bihari'),
          _buildInfoRow('Aho riherereye', '${_groupData!['province']}, ${_groupData!['district']}, ${_groupData!['sector']}'),
          _buildInfoRow('Agaciro k\'umugabane', Formatters.formatCurrency((_groupData!['shareValue'] ?? 0).toDouble())),
          _buildInfoRow('Inyungu ku nguzanyo', '${_groupData!['loanInterestRate']}%'),
          _buildInfoRow('Igihe cyo gutanga', _groupData!['contributionFrequency'] ?? 'Buri cyumweru'),
          _buildInfoRow('Igihe cyashinzwe', Formatters.formatDate(DateTime.parse(_groupData!['createdAt']))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Divider(),
        ],
      ),
    );
  }
}
