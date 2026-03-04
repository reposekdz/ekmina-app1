import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class JoinGroupScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  
  const JoinGroupScreen({super.key, required this.groupId, required this.userId});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  Map<String, dynamic>? _groupData;
  bool _loading = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    setState(() => _loading = true);
    try {
      final response = await _dio.get('/groups/${widget.groupId}');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _groupData = response.data['group'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emeza kwishyura'),
        content: Text('Uzishyura ${_groupData!['joinFee'].toStringAsFixed(0)} RWF kuva muri wallet yawe. Komeza?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yego, ishyura')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _joining = true);
    try {
      final response = await _dio.post('/groups/${widget.groupId}/join', data: {'userId': widget.userId});

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Wishyuye neza. Tegereza kwemezwa.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e is DioException ? e.response?.data['error'] ?? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg ?? 'Ikosa ryabaye'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kwinjira mutsinda')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_groupData!['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_groupData!['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_groupData!['description'] != null)
                      Text(_groupData!['description'], style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    _buildInfoRow('Aho: ', '${_groupData!['province']}, ${_groupData!['district']}'),
                    _buildInfoRow('Abanyamuryango: ', '${_groupData!['memberCount']}'),
                    _buildInfoRow('Agaciro k\'imigabane: ', '${_groupData!['shareValue'].toStringAsFixed(0)} RWF'),
                    _buildInfoRow('Amafaranga yo kwinjira: ', '${_groupData!['joinFee'].toStringAsFixed(0)} RWF'),
                    _buildInfoRow('Igihe cyo gutanga: ', _groupData!['contributionFrequency']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text('Amakuru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('• Amafaranga azavamo muri wallet yawe', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('• Uzishyura ${_groupData!['joinFee'].toStringAsFixed(0)} RWF nk\'amafaranga yo kwinjira', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('• Umuyobozi w\'itsinda azakwemeza nyuma yo kwishyura', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('• Nyuma yo kwemezwa, uzatangira gutanga imisanzu', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _joining ? null : _joinGroup,
                child: _joining
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Injira mutsinda (${_groupData!['joinFee'].toStringAsFixed(0)} RWF)', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
