import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'interactive_join_group_screen.dart';

class EnhancedPublicGroupsScreen extends StatefulWidget {
  final String userId;
  
  const EnhancedPublicGroupsScreen({super.key, required this.userId});

  @override
  State<EnhancedPublicGroupsScreen> createState() => _EnhancedPublicGroupsScreenState();
}

class _EnhancedPublicGroupsScreenState extends State<EnhancedPublicGroupsScreen> {
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  final _searchController = TextEditingController();
  List<dynamic> _groups = [];
  List<dynamic> _filteredGroups = [];
  bool _loading = true;
  String? _selectedProvince;
  String? _selectedDistrict;

  final List<String> _provinces = ['Kigali', 'Eastern', 'Northern', 'Southern', 'Western'];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final response = await _dio.get('/groups', queryParameters: {'isPublic': 'true'});
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _groups = response.data['groups'] ?? [];
          _filteredGroups = _groups;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterGroups() {
    setState(() {
      _filteredGroups = _groups.where((group) {
        final matchesSearch = _searchController.text.isEmpty ||
            group['name'].toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesProvince = _selectedProvince == null || group['province'] == _selectedProvince;
        final matchesDistrict = _selectedDistrict == null || group['district'] == _selectedDistrict;
        return matchesSearch && matchesProvince && matchesDistrict;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amatsinda rusange'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGroups),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Shakisha itsinda...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => _filterGroups(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedProvince,
                        decoration: InputDecoration(
                          labelText: 'Intara',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Zose')),
                          ..._provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedProvince = value;
                            _selectedDistrict = null;
                          });
                          _filterGroups();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: InputDecoration(
                          labelText: 'Akarere',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Zose')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDistrict = value);
                          _filterGroups();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredGroups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('Nta matsinda yabonetse', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadGroups,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredGroups.length,
                          itemBuilder: (context, index) => _buildGroupCard(_filteredGroups[index]),
                        ),
                      ),
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InteractiveJoinGroupScreen(groupId: group['id'], userId: widget.userId),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
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
                    child: Text(group['name'][0], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${group['province']}, ${group['district']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A86B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${group['joinFee'].toStringAsFixed(0)} RWF', style: const TextStyle(color: Color(0xFF00A86B), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              if (group['description'] != null) ...[
                const SizedBox(height: 12),
                Text(group['description'], style: TextStyle(color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.people, '${group['_count']?['members'] ?? 0} abanyamuryango'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.account_balance, '${group['escrowBalance']?.toStringAsFixed(0) ?? '0'} RWF'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InteractiveJoinGroupScreen(groupId: group['id'], userId: widget.userId),
                        ),
                      ),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Reba'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00A86B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InteractiveJoinGroupScreen(groupId: group['id'], userId: widget.userId),
                        ),
                      ),
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Injira'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
                    ),
                  ),
                ],
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
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
