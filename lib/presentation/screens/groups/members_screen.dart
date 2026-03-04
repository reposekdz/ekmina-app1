import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';
import 'add_member_screen.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String userId;
  final bool isAdmin;
  
  const MembersScreen({super.key, required this.groupId, required this.userId, required this.isAdmin});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  List<dynamic> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getGroupMembers(widget.groupId);
      if (mounted) {
        setState(() {
          _members = response['members'] ?? [];
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

  Future<void> _removeMember(String membershipId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kuraho umunyamuryango?'),
        content: const Text('Uremeza ko ushaka gukuraho uyu munyamuryango mu itsinda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yego, mukureho'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.manageGroup(widget.groupId, widget.userId, 'remove_member', {'membershipId': membershipId});
      _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Umunyamuryango yakuweho neza'), backgroundColor: Colors.green),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abanyamuryango', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddMemberScreen(groupId: widget.groupId, userId: widget.userId)),
                );
                if (result == true) _loadMembers();
              },
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMembers),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text('Nta banyamuryango babonetse'),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadMembers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final user = member['user'];
                      final isMe = user['id'] == widget.userId;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                            child: Text(user['name']?[0].toUpperCase() ?? 'U',
                              style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(user['name'] ?? 'Umunyamuryango',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? AppTheme.primaryGreen : Colors.black)),
                          subtitle: Text(user['phone'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (member['role'] == 'FOUNDER' || member['role'] == 'ADMIN')
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(member['role'] ?? 'MEMBER',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                    color: (member['role'] == 'FOUNDER' || member['role'] == 'ADMIN') ? Colors.orange : Colors.blue)),
                              ),
                              if (widget.isAdmin && !isMe && member['role'] != 'FOUNDER')
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'remove', child: Text('Kuraho')),
                                    const PopupMenuItem(value: 'make_admin', child: Text('Guhindura Admin')),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'remove') _removeMember(member['id']);
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
