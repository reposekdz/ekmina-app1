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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            title: const Text('Amatsinda', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(LucideIcons.search), onPressed: () {}),
              IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _loadData),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Yanjye'),
                Tab(text: 'Shaka Amatsinda'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMyGroupsList(),
                  _buildPublicGroupsList(),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/create'),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Kurema Itsinda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBlue,
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildMyGroupsList() {
    if (_myGroups.isEmpty) {
      return _buildEmptyState(
        'Nta matsinda urabamo', 
        'Kora itsinda ryawe cyangwa ubashe kwinjira mu rindi kugira ngo utangire kubika.',
        LucideIcons.users,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: _myGroups.length,
        itemBuilder: (context, index) {
          final group = _myGroups[index];
          return _buildGroupCard(group, isMember: true, index: index);
        },
      ),
    );
  }

  Widget _buildPublicGroupsList() {
    final myGroupIds = _myGroups.map((g) => g['id']).toSet();
    final joinableGroups = _publicGroups.where((g) => !myGroupIds.contains(g['id'])).toList();

    if (joinableGroups.isEmpty) {
      return _buildEmptyState(
        'Nta yandi matsinda yabonetse', 
        'Gerageza gushakisha andi matsinda akwegereye mu karere kawe.',
        LucideIcons.search,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: joinableGroups.length,
        itemBuilder: (context, index) {
          final group = joinableGroups[index];
          return _buildGroupCard(group, isMember: false, index: index);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: AppTheme.primaryBlue.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              subtitle, 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5),
            ),
          ],
        ).animate().fadeIn().scale(),
      ),
    );
  }

  Widget _buildGroupCard(dynamic group, {required bool isMember, required int index}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/groups/${group['id']}'),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isMember ? AppTheme.primaryGradient : null,
                      color: !isMember ? AppTheme.primaryYellow.withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      LucideIcons.users, 
                      color: isMember ? Colors.white : AppTheme.primaryYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name'] ?? 'Itsinda', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${group['district']}, ${group['sector']}', 
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isMember)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Uri Umunyamuryango', 
                        style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat(LucideIcons.userPlus, '${group['memberCount'] ?? 0}', 'Abantu'),
                  _buildMiniStat(LucideIcons.circleDollarSign, Formatters.formatCompactNumber(group['shareValue'] ?? 0), 'Umugabane'),
                  if (isMember)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Balance', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          Formatters.formatCurrency((group['escrowBalance'] ?? 0).toDouble()),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 16),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _handleJoinGroup(group['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        minimumSize: const Size(100, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Kwinjira', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Future<void> _handleJoinGroup(String groupId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.joinGroup(groupId, _userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubusabe bwawe bwo kwinjira bwoherejwe!'), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.handleError(e)), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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
