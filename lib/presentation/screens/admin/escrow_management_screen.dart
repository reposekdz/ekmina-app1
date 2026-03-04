import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class EscrowManagementScreen extends StatefulWidget {
  final String adminId;
  const EscrowManagementScreen({super.key, required this.adminId});

  @override
  State<EscrowManagementScreen> createState() => _EscrowManagementScreenState();
}

class _EscrowManagementScreenState extends State<EscrowManagementScreen> with SingleTickerProviderStateMixin {
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  final _passwordController = TextEditingController();
  late TabController _tabController;
  Map<String, dynamic>? _escrowData;
  bool _loading = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _authenticate() async {
    try {
      final response = await _dio.post('/escrow/authenticate', data: {'adminId': widget.adminId, 'password': _passwordController.text});
      if (response.statusCode == 200 && mounted) {
        setState(() => _authenticated = true);
        _loadEscrowData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ijambo ryibanga ntibikora'), backgroundColor: Colors.red));
    }
  }

  Future<void> _loadEscrowData() async {
    setState(() => _loading = true);
    try {
      final response = await _dio.get('/escrow/dashboard', queryParameters: {'adminId': widget.adminId});
      if (response.statusCode == 200 && mounted) setState(() {_escrowData = response.data; _loading = false;});
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Escrow - Umutekano')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 100, color: Color(0xFF00A86B)),
              const SizedBox(height: 30),
              const Text('Injiza ijambo ryibanga rya Escrow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Ijambo ryibanga', prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _authenticate, child: const Text('Injira', style: TextStyle(fontSize: 16)))),
            ],
          ),
        ),
      );
    }

    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Escrow')), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Escrow Management'), bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Amasoko'), Tab(text: 'Amatsinda'), Tab(text: 'Ibyakozwe')])),
      body: TabBarView(controller: _tabController, children: [_buildOverviewTab(), _buildGroupsTab(), _buildTransactionsTab()]),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(color: const Color(0xFF00A86B), child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Text('Amafaranga yose muri Escrow', style: TextStyle(color: Colors.white70, fontSize: 16)), const SizedBox(height: 8), Text('${_escrowData!['totalBalance'].toStringAsFixed(0)} RWF', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))]))),
        const SizedBox(height: 16),
        _buildStatCard('Amafaranga y\'amatsinda', _escrowData!['groupsBalance'], Icons.groups),
        _buildStatCard('Amafaranga y\'amafaranga yo kurema', _escrowData!['feesBalance'], Icons.payment),
      ],
    );
  }

  Widget _buildStatCard(String title, double amount, IconData icon) {
    return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFF00A86B), child: Icon(icon, color: Colors.white)), title: Text(title), trailing: Text('${amount.toStringAsFixed(0)} RWF', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))));
  }

  Widget _buildGroupsTab() {
    final groups = _escrowData!['groups'] as List;
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: groups.length, itemBuilder: (context, index) {
      final group = groups[index];
      return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(title: Text(group['name'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Abanyamuryango: ${group['memberCount']}'), trailing: Text('${group['escrowBalance'].toStringAsFixed(0)} RWF', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A86B)))));
    });
  }

  Widget _buildTransactionsTab() {
    final transactions = _escrowData!['transactions'] as List;
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: transactions.length, itemBuilder: (context, index) {
      final tx = transactions[index];
      return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: Icon(tx['type'] == 'IN' ? Icons.arrow_downward : Icons.arrow_upward, color: tx['type'] == 'IN' ? Colors.green : Colors.red), title: Text(tx['description']), subtitle: Text(tx['date']), trailing: Text('${tx['amount'].toStringAsFixed(0)} RWF', style: TextStyle(fontWeight: FontWeight.bold, color: tx['type'] == 'IN' ? Colors.green : Colors.red))));
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
