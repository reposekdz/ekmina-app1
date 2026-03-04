import 'package:flutter/material.dart';

class PublicGroupsScreen extends StatefulWidget {
  final String userId;
  const PublicGroupsScreen({super.key, required this.userId});

  @override
  State<PublicGroupsScreen> createState() => _PublicGroupsScreenState();
}

class _PublicGroupsScreenState extends State<PublicGroupsScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterProvince = 'All';

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _groups = List.generate(
        10,
        (i) => {
          'id': 'group_$i',
          'name': 'Ikimina ${i + 1}',
          'description': 'Community savings group for mutual support',
          'memberCount': 15 + i,
          'shareValue': 5000.0,
          'joinFee': 2000.0,
          'province': i % 2 == 0 ? 'Kigali' : 'Eastern',
          'district': 'District ${i + 1}',
          'contributionFrequency': i % 3 == 0 ? 'WEEKLY' : 'MONTHLY',
        },
      );
      _loading = false;
    });
  }

  void _joinGroup(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${group['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join Fee: ${group['joinFee']} RWF'),
            Text('Share Value: ${group['shareValue']} RWF'),
            const SizedBox(height: 12),
            const Text('By joining, you agree to the group rules and contribution schedule.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Join request sent! Waiting for admin approval.'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Join Group'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = _groups.where((g) {
      final matchesSearch = g['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesProvince = _filterProvince == 'All' || g['province'] == _filterProvince;
      return matchesSearch && matchesProvince;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Groups'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filteredGroups.isEmpty
                    ? const Center(child: Text('No groups found'))
                    : RefreshIndicator(
                        onRefresh: _loadGroups,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredGroups.length,
                          itemBuilder: (context, index) => _buildGroupCard(filteredGroups[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search groups...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('Province: ', style: TextStyle(fontWeight: FontWeight.w600)),
          DropdownButton<String>(
            value: _filterProvince,
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Kigali', child: Text('Kigali')),
              DropdownMenuItem(value: 'Eastern', child: Text('Eastern')),
              DropdownMenuItem(value: 'Western', child: Text('Western')),
              DropdownMenuItem(value: 'Northern', child: Text('Northern')),
              DropdownMenuItem(value: 'Southern', child: Text('Southern')),
            ],
            onChanged: (value) => setState(() => _filterProvince = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showGroupDetails(group),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00A86B),
                    child: Text(group['name'][0], style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${group['province']} - ${group['district']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text('${group['memberCount']} members'),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(group['description'], style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.money, '${group['shareValue']} RWF/share'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.calendar_today, group['contributionFrequency']),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _joinGroup(group),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Join Group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A86B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  void _showGroupDetails(Map<String, dynamic> group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(group['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${group['province']} - ${group['district']}', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            _buildDetailRow('Members', '${group['memberCount']} active members'),
            _buildDetailRow('Share Value', '${group['shareValue']} RWF'),
            _buildDetailRow('Join Fee', '${group['joinFee']} RWF'),
            _buildDetailRow('Contribution', group['contributionFrequency']),
            const SizedBox(height: 20),
            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(group['description']),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _joinGroup(group);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Join This Group', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
