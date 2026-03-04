import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _myGroups = [];
  List<dynamic> _publicGroups = [];
  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final myGroupsData = await api.getGroups(_userId!);
      // Assuming searchUsers or similar for public groups
      final publicGroupsData = await api.getGroups('all');

      if (mounted) {
        setState(() {
          _myGroups = myGroupsData['groups'] ?? [];
          _publicGroups = publicGroupsData['groups'] ?? [];
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
        title: const Text('Amatsinda', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Yanjye'),
            Tab(text: 'Ayabandi'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyGroupsList(),
                _buildPublicGroupsList(),
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

  Widget _buildMyGroupsList() {
    if (_myGroups.isEmpty) {
      return _buildEmptyState('Nta matsinda urabamo', 'Kora itsinda ryawe cyangwa ubashe kwinjira mu rindi.');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myGroups.length,
        itemBuilder: (context, index) {
          final group = _myGroups[index];
          return _buildGroupCard(group, isMember: true);
        },
      ),
    );
  }

  Widget _buildPublicGroupsList() {
    // Filter out groups I'm already in
    final myGroupIds = _myGroups.map((g) => g['id']).toSet();
    final joinableGroups = _publicGroups.where((g) => !myGroupIds.contains(g['id'])).toList();

    if (joinableGroups.isEmpty) {
      return _buildEmptyState('Nta yandi matsinda yabonetse', 'Gerageza gushakisha andi matsinda akwegereye.');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: joinableGroups.length,
        itemBuilder: (context, index) {
          final group = joinableGroups[index];
          return _buildGroupCard(group, isMember: false);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/groups/create'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Kurema itsinda'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(dynamic group, {required bool isMember}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () => context.push('/groups/${group['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: const Icon(Icons.group, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group['name'] ?? 'Itsinda', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${group['district']}, ${group['sector']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isMember)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Text('Member', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGroupInfoItem(Icons.people_outline, '${group['memberCount'] ?? 0} abantu'),
                  _buildGroupInfoItem(Icons.payments_outlined, '${Formatters.formatCompactNumber(group['shareValue'] ?? 0)} RWF'),
                  if (isMember)
                    Text(Formatters.formatCurrency((group['escrowBalance'] ?? 0).toDouble()),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen))
                  else
                    ElevatedButton(
                      onPressed: () => _handleJoinGroup(group['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(80, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Kwinjira', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupInfoItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Future<void> _handleJoinGroup(String groupId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.joinGroup(groupId, _userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubusabe bwawe bwo kwinjira bwoherejwe!'), backgroundColor: Colors.green),
        );
        _loadData();
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
