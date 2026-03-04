import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class DividendsScreen extends StatefulWidget {
  final String groupId;
  final String membershipId;
  final String userId;
  final bool isAdmin;
  
  const DividendsScreen({super.key, required this.groupId, required this.membershipId, required this.userId, this.isAdmin = false});

  @override
  State<DividendsScreen> createState() => _DividendsScreenState();
}

class _DividendsScreenState extends State<DividendsScreen> {
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  List<dynamic> _dividends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDividends();
  }

  Future<void> _loadDividends() async {
    setState(() => _loading = true);
    try {
      final response = await _dio.get('/dividends', queryParameters: {'membershipId': widget.membershipId});
      if (response.statusCode == 200 && mounted) setState(() {_dividends = response.data['dividends']; _loading = false;});
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _claimDividend(String dividendId) async {
    try {
      final response = await _dio.post('/dividends', data: {'action': 'claim', 'dividendId': dividendId, 'membershipId': widget.membershipId});
      if (response.statusCode == 200 && mounted) {
        _loadDividends();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  Future<void> _distributeDividends() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emeza'),
        content: const Text('Urashaka kugabana inyungu kubanyamuryango bose?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yego')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _dio.post('/dividends', data: {'groupId': widget.groupId, 'action': 'distribute'});
      if (response.statusCode == 200 && mounted) {
        _loadDividends();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Inyungu')), body: const Center(child: CircularProgressIndicator()));

    final pending = _dividends.where((d) => d['status'] == 'PENDING').toList();
    final paid = _dividends.where((d) => d['status'] == 'PAID').toList();
    final totalEarned = paid.fold<double>(0, (sum, d) => sum + d['amount']);

    return Scaffold(
      appBar: AppBar(title: const Text('Inyungu'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDividends)]),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF00A86B), Colors.green.shade700])),
            child: Column(
              children: [
                const Text('Inyungu zawe zose', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('${totalEarned.toStringAsFixed(0)} RWF', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${paid.length} ibyishyuwe', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (pending.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.all(16), child: Text('Inyungu zitegereje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ...pending.map((d) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF00A86B), child: Icon(Icons.monetization_on, color: Colors.white)),
                title: Text('${d['amount'].toStringAsFixed(0)} RWF', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Itariki: ${DateTime.parse(d['cycleEndDate']).day}/${DateTime.parse(d['cycleEndDate']).month}/${DateTime.parse(d['cycleEndDate']).year}'),
                trailing: ElevatedButton(onPressed: () => _claimDividend(d['id']), child: const Text('Hamagara')),
              ),
            )),
          ],
          if (paid.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.all(16), child: Text('Amateka', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: paid.length,
                itemBuilder: (context, index) {
                  final d = paid[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                      title: Text('${d['amount'].toStringAsFixed(0)} RWF', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Yishyuwe: ${DateTime.parse(d['paidDate']).day}/${DateTime.parse(d['paidDate']).month}/${DateTime.parse(d['paidDate']).year}'),
                    ),
                  );
                },
              ),
            ),
          ],
          if (_dividends.isEmpty) const Expanded(child: Center(child: Text('Nta nyungu'))),
        ],
      ),
      floatingActionButton: widget.isAdmin ? FloatingActionButton.extended(onPressed: _distributeDividends, icon: const Icon(Icons.share), label: const Text('Gabana inyungu')) : null,
    );
  }
}
