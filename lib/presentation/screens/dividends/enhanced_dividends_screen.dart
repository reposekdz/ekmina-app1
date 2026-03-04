import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class EnhancedDividendsScreen extends StatefulWidget {
  final String groupId;
  final String membershipId;
  final String userId;
  final bool isAdmin;
  
  const EnhancedDividendsScreen({super.key, required this.groupId, required this.membershipId, required this.userId, this.isAdmin = false});

  @override
  State<EnhancedDividendsScreen> createState() => _EnhancedDividendsScreenState();
}

class _EnhancedDividendsScreenState extends State<EnhancedDividendsScreen> with SingleTickerProviderStateMixin {
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  late TabController _tabController;
  List<dynamic> _dividends = [];
  Map<String, dynamic>? _groupData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final [dividendsResponse, groupResponse] = await Future.wait([
        _dio.get('/dividends', queryParameters: {'membershipId': widget.membershipId}),
        _dio.get('/groups/${widget.groupId}'),
      ]);
      
      if (mounted) {
        setState(() {
          _dividends = dividendsResponse.data['dividends'];
          _groupData = groupResponse.data['group'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _claimDividend(String dividendId, double amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emeza'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, size: 64, color: Color(0xFF00A86B)),
            const SizedBox(height: 16),
            Text('Urashaka gufata ${amount.toStringAsFixed(0)} RWF?'),
            const SizedBox(height: 8),
            const Text('Amafaranga azashyirwa muri wallet yawe.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yego, fata')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _dio.post('/dividends', data: {'action': 'claim', 'dividendId': dividendId, 'membershipId': widget.membershipId});
      if (response.statusCode == 200 && mounted) {
        _loadData();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Byagenze neza!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text('${amount.toStringAsFixed(0)} RWF yashyizwe muri wallet yawe.'),
              ],
            ),
            actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Sawa'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  Future<void> _distributeDividends() async {
    final profitPool = _groupData?['profitPool'] ?? 0.0;
    
    if (profitPool <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nta nyungu zihari zo kugabana'), backgroundColor: Colors.orange));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gabana inyungu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Urashaka kugabana inyungu kubanyamuryango bose?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Inyungu zose:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${profitPool.toStringAsFixed(0)} RWF', style: const TextStyle(color: Color(0xFF00A86B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Izagabanwa hashingiwe ku migabane', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hagarika')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yego, gabana')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _dio.post('/dividends', data: {'groupId': widget.groupId, 'action': 'distribute'});
      if (response.statusCode == 200 && mounted) {
        _loadData();
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
    final totalPending = pending.fold<double>(0, (sum, d) => sum + d['amount']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inyungu'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
        bottom: TabBar(controller: _tabController, tabs: [Tab(text: 'Zitegereje (${pending.length})'), Tab(text: 'Amateka (${paid.length})')]),
      ),
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
                if (totalPending > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: Text('${totalPending.toStringAsFixed(0)} RWF zitegereje', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                pending.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.monetization_on_outlined, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), Text('Nta nyungu zitegereje', style: TextStyle(fontSize: 18, color: Colors.grey.shade600))])) : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final d = pending[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(radius: 24, backgroundColor: const Color(0xFF00A86B).withOpacity(0.1), child: const Icon(Icons.monetization_on, color: Color(0xFF00A86B))),
                        title: Text('${d['amount'].toStringAsFixed(0)} RWF', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Itariki: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(d['cycleEndDate']))}'),
                            const SizedBox(height: 4),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)), child: const Text('Zitegereje', style: TextStyle(fontSize: 10, color: Colors.orange))),
                          ],
                        ),
                        trailing: ElevatedButton(onPressed: () => _claimDividend(d['id'], d['amount'].toDouble()), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B)), child: const Text('Fata')),
                      ),
                    );
                  },
                ),
                paid.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), Text('Nta mateka', style: TextStyle(fontSize: 18, color: Colors.grey.shade600))])) : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: paid.length,
                  itemBuilder: (context, index) {
                    final d = paid[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                        title: Text('${d['amount'].toStringAsFixed(0)} RWF', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Yishyuwe: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(d['paidDate']))}'),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin ? FloatingActionButton.extended(onPressed: _distributeDividends, icon: const Icon(Icons.share), label: const Text('Gabana inyungu'), backgroundColor: const Color(0xFF00A86B)) : null,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
