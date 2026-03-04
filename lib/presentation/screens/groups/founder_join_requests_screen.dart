import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class FounderJoinRequestsScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  
  const FounderJoinRequestsScreen({super.key, required this.groupId, required this.userId});

  @override
  State<FounderJoinRequestsScreen> createState() => _FounderJoinRequestsScreenState();
}

class _FounderJoinRequestsScreenState extends State<FounderJoinRequestsScreen> with SingleTickerProviderStateMixin {
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  late TabController _tabController;
  List<dynamic> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final response = await _dio.get('/groups/${widget.groupId}/join-requests', queryParameters: {'userId': widget.userId});
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _requests = response.data['requests'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approveRequest(String membershipId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emeza umunyamuryango'),
        content: Text('Urashaka kwemeza $userName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yego, emeza')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _dio.put('/groups/${widget.groupId}/manage', data: {
        'userId': widget.userId,
        'action': 'approve_member',
        'data': {'membershipId': membershipId}
      });

      if (response.statusCode == 200 && mounted) {
        _loadRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Umunyamuryango yemewe neza'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectRequest(String membershipId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anza usaba'),
        content: Text('Urashaka kwanga $userName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yego, anga'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _dio.put('/groups/${widget.groupId}/manage', data: {
        'userId': widget.userId,
        'action': 'reject_member',
        'data': {'membershipId': membershipId}
      });

      if (response.statusCode == 200 && mounted) {
        _loadRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usaba yanzwe'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Abasaba kwinjira')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pending = _requests.where((r) => r['status'] == 'PENDING').toList();
    final approved = _requests.where((r) => r['status'] == 'ACTIVE').toList();
    final rejected = _requests.where((r) => r['status'] == 'REJECTED').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abasaba kwinjira'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests)],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Bategereje (${pending.length})'),
            Tab(text: 'Byemejwe (${approved.length})'),
            Tab(text: 'Byanzwe (${rejected.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(pending),
          _buildApprovedTab(approved),
          _buildRejectedTab(rejected),
        ],
      ),
    );
  }

  Widget _buildPendingTab(List<dynamic> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Nta basaba bategereje', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final feePaid = request['feePaid'] ?? false;
        final joinedAt = DateTime.parse(request['joinedAt']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF00A86B),
                      child: Text(request['user']['name'][0], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request['user']['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(request['user']['phone'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: feePaid ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(feePaid ? Icons.check_circle : Icons.pending, size: 14, color: feePaid ? Colors.green : Colors.orange),
                          const SizedBox(width: 4),
                          Text(feePaid ? 'Yishyuye' : 'Ntiyishyura', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: feePaid ? Colors.green : Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Itariki yasabye:', style: TextStyle(fontSize: 12)),
                          Text(DateFormat('dd/MM/yyyy HH:mm').format(joinedAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (feePaid) ...[
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amafaranga yishyuwe:', style: TextStyle(fontSize: 12)),
                            Text('${request['joinFee']?.toStringAsFixed(0) ?? '0'} RWF', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectRequest(request['id'], request['user']['name']),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Anga'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: feePaid ? () => _approveRequest(request['id'], request['user']['name']) : null,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Emeza'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
                      ),
                    ),
                  ],
                ),
                if (!feePaid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Ntushobora kwemeza kuko atishyuye', style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApprovedTab(List<dynamic> approved) {
    if (approved.isEmpty) {
      return Center(child: Text('Nta byemejwe', style: TextStyle(color: Colors.grey.shade600)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: approved.length,
      itemBuilder: (context, index) {
        final request = approved[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.green, child: const Icon(Icons.check, color: Colors.white)),
            title: Text(request['user']['name']),
            subtitle: Text('Yemejwe: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(request['approvedAt']))}'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }

  Widget _buildRejectedTab(List<dynamic> rejected) {
    if (rejected.isEmpty) {
      return Center(child: Text('Nta byanzwe', style: TextStyle(color: Colors.grey.shade600)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rejected.length,
      itemBuilder: (context, index) {
        final request = rejected[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.red, child: const Icon(Icons.close, color: Colors.white)),
            title: Text(request['user']['name']),
            subtitle: const Text('Yanzwe'),
            trailing: const Icon(Icons.cancel, color: Colors.red),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
