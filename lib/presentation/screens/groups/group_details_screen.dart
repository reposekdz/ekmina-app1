import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_groupData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Itsinda')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('Ntitubashije kubona itsinda'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Ongera ugerageze')),
            ],
          ),
        ),
      );
    }

    final isFounder = _groupData!['founderId'] == _userId;
    final isAdmin = (_membershipData?['role'] == 'ADMIN' || isFounder);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(isFounder),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildQuickStats().animate().fadeIn().slideY(begin: 0.1),
                _buildActionGrid(isAdmin).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                _buildGroupInfo().animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _membershipData != null ? Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/contributions?groupId=${widget.groupId}'),
          icon: const Icon(LucideIcons.wallet, color: Colors.white),
          label: const Text('Tanga Umusanzu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ).animate().scale(delay: 600.ms) : null,
    );
  }

  Widget _buildSliverAppBar(bool isFounder) {
    return SliverAppBar(
      expandedHeight: 240.0,
      floating: false,
      pinned: true,
      stretch: true,
      actions: [
        if (isFounder)
          IconButton(
            icon: const Icon(LucideIcons.layoutDashboard, color: Colors.white),
            onPressed: () => context.push('/groups/${widget.groupId}/dashboard?userId=$_userId'),
          ),
        IconButton(icon: const Icon(LucideIcons.refreshCw, color: Colors.white), onPressed: _loadData),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          _groupData!['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: CircleAvatar(radius: 120, backgroundColor: Colors.white.withOpacity(0.05)),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                ),
                child: const Icon(LucideIcons.users, size: 60, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Abantu', '${_groupData!['memberCount']}', LucideIcons.userPlus, AppTheme.primaryBlue),
          _buildStatItem('Escrow', Formatters.formatCompactNumber(_groupData!['escrowBalance']), LucideIcons.shieldCheck, AppTheme.primaryGreen),
          _buildStatItem('Shares', Formatters.formatCompactNumber(_membershipData?['totalShares'] ?? 0), LucideIcons.pieChart, AppTheme.primaryYellow),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActionGrid(bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ibikorwa by\'itsinda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              _buildActionItem('Imisanzu', LucideIcons.coins, AppTheme.primaryBlue, () => context.push('/contributions?groupId=${widget.groupId}')),
              _buildActionItem('Inguzanyo', LucideIcons.landmark, AppTheme.accentIndigo, () => context.push('/loans?groupId=${widget.groupId}')),
              _buildActionItem('Abantu', LucideIcons.users, Colors.teal, () => context.push('/groups/${widget.groupId}/members')),
              _buildActionItem('Inama', LucideIcons.calendar, Colors.orange, () => context.push('/meetings?groupId=${widget.groupId}')),
              _buildActionItem('Chat', LucideIcons.messageSquare, Colors.pink, () => context.push('/groups/${widget.groupId}/chat')),
              _buildActionItem('Raporo', LucideIcons.barChart3, AppTheme.primaryGreen, () => context.push('/reports?groupId=${widget.groupId}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.info, size: 20, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text('Amakuru y\'inyongezo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Ibisobanuro', _groupData!['description'] ?? 'Nta bisobanuro bihari'),
            _buildInfoRow('Aho riherereye', '${_groupData!['district']}, ${_groupData!['sector']}'),
            _buildInfoRow('Agaciro k\'umugabane', Formatters.formatCurrency((_groupData!['shareValue'] ?? 0).toDouble())),
            _buildInfoRow('Inyungu ku nguzanyo', '${_groupData!['loanInterestRate']}%'),
            _buildInfoRow('Igihe cyashinzwe', Formatters.formatDate(DateTime.parse(_groupData!['createdAt']))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade100, height: 1),
        ],
      ),
    );
  }
}
