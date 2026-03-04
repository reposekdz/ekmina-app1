import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class InteractiveJoinGroupScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  
  const InteractiveJoinGroupScreen({super.key, required this.groupId, required this.userId});

  @override
  State<InteractiveJoinGroupScreen> createState() => _InteractiveJoinGroupScreenState();
}

class _InteractiveJoinGroupScreenState extends State<InteractiveJoinGroupScreen> with SingleTickerProviderStateMixin {
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  late TabController _tabController;
  Map<String, dynamic>? _groupData;
  Map<String, dynamic>? _walletData;
  bool _loading = true;
  bool _joining = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final [groupResponse, walletResponse] = await Future.wait([
        _dio.get('/groups/${widget.groupId}'),
        _dio.get('/wallet', queryParameters: {'userId': widget.userId}),
      ]);
      
      if (mounted) {
        setState(() {
          _groupData = groupResponse.data['group'];
          _walletData = walletResponse.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinGroup() async {
    final joinFee = _groupData!['joinFee'].toDouble();
    final walletBalance = _walletData!['balance'].toDouble();

    if (walletBalance < joinFee) {
      _showInsufficientBalanceDialog(joinFee, walletBalance);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emeza kwishyura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Uzishyura ${joinFee.toStringAsFixed(0)} RWF kuva muri wallet yawe.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Wallet yawe:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${walletBalance.toStringAsFixed(0)} RWF'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amafaranga yo kwinjira:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${joinFee.toStringAsFixed(0)} RWF', style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Asigaye:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${(walletBalance - joinFee).toStringAsFixed(0)} RWF', style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hagarika')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yego, ishyura')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _joining = true);
    try {
      final response = await _dio.post('/groups/${widget.groupId}/join', data: {'userId': widget.userId});

      if (response.statusCode == 200 && mounted) {
        _showSuccessDialog();
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

  void _showInsufficientBalanceDialog(double required, double current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Amafaranga ntahagije'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Ukeneye ${required.toStringAsFixed(0)} RWF ariko ufite ${current.toStringAsFixed(0)} RWF.'),
            const SizedBox(height: 8),
            Text('Shyiramo ${(required - current).toStringAsFixed(0)} RWF kugirango ubashe kwinjira.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/wallet');
            },
            child: const Text('Shyiramo amafaranga'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Byagenze neza!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Wishyuye neza amafaranga yo kwinjira.', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Tegereza umuyobozi w\'itsinda akwemeze.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  const Text('Uzahamagariwe na SMS', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Iyo wemejwe', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Sawa'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        title: Text(_groupData!['name']),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Amakuru'),
            Tab(icon: Icon(Icons.people), text: 'Abanyamuryango'),
            Tab(icon: Icon(Icons.settings), text: 'Amategeko'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildMembersTab(),
          _buildRulesTab(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _joining ? null : _joinGroup,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF00A86B),
            ),
            child: _joining
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Injira mutsinda (${_groupData!['joinFee'].toStringAsFixed(0)} RWF)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF00A86B),
                        child: Text(_groupData!['name'][0], style: const TextStyle(color: Colors.white, fontSize: 24)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_groupData!['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            if (_groupData!['description'] != null)
                              Text(_groupData!['description'], style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(Icons.location_on, 'Aho', '${_groupData!['province']}, ${_groupData!['district']}'),
                  _buildInfoRow(Icons.people, 'Abanyamuryango', '${_groupData!['memberCount']}'),
                  _buildInfoRow(Icons.account_balance, 'Escrow', '${_groupData!['escrowBalance'].toStringAsFixed(0)} RWF'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Amafaranga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _buildPriceRow('Agaciro k\'imigabane', _groupData!['shareValue']),
                const Divider(height: 1),
                _buildPriceRow('Amafaranga yo kwinjira', _groupData!['joinFee'], highlight: true),
                const Divider(height: 1),
                _buildPriceRow('Ihano', _groupData!['penaltyAmount']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('${_groupData!['memberCount']} abanyamuryango', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Uzabona abanyamuryango nyuma yo kwinjira', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRulesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRuleCard('Igihe cyo gutanga', _groupData!['contributionFrequency'], Icons.calendar_today),
        _buildRuleCard('Inyungu z\'inguzanyo', '${_groupData!['loanInterestRate']}%', Icons.percent),
        _buildRuleCard('Kwemeza inguzanyo', '${_groupData!['approvalThreshold']} abayobozi', Icons.how_to_vote),
        _buildRuleCard('Itsinda', _groupData!['isPublic'] ? 'Rusange' : 'Ryihishe', Icons.public),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool highlight = false}) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        '${amount.toStringAsFixed(0)} RWF',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: highlight ? const Color(0xFF00A86B) : null,
        ),
      ),
    );
  }

  Widget _buildRuleCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00A86B).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF00A86B)),
        ),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
