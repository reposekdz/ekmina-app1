import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GuarantorManagementScreen extends StatefulWidget {
  final String loanId;
  const GuarantorManagementScreen({super.key, required this.loanId});

  @override
  State<GuarantorManagementScreen> createState() => _GuarantorManagementScreenState();
}

class _GuarantorManagementScreenState extends State<GuarantorManagementScreen> {
  final List<Map<String, dynamic>> _guarantors = [];
  final List<Map<String, dynamic>> _availableMembers = [
    {'id': '1', 'name': 'Jean Uwimana', 'phone': '0788123456', 'shares': '1,200,000 RWF', 'status': 'active'},
    {'id': '2', 'name': 'Marie Mukamana', 'phone': '0788234567', 'shares': '950,000 RWF', 'status': 'active'},
    {'id': '3', 'name': 'Paul Habimana', 'phone': '0788345678', 'shares': '1,500,000 RWF', 'status': 'active'},
    {'id': '4', 'name': 'Grace Uwase', 'phone': '0788456789', 'shares': '800,000 RWF', 'status': 'active'},
  ];

  void _addGuarantor(Map<String, dynamic> member) {
    if (_guarantors.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ntushobora gushyiraho abanzi b\'abantu 3')),
      );
      return;
    }
    setState(() {
      _guarantors.add({...member, 'status': 'pending'});
    });
  }

  void _removeGuarantor(String id) {
    setState(() {
      _guarantors.removeWhere((g) => g['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abamenyesha'),
        actions: [
          if (_guarantors.length >= 2)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abamenyesha bemejwe!')),
                );
                context.pop();
              },
              child: const Text('Emeza'),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF00A86B).withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF00A86B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ukeneye abamenyesha ${2 - _guarantors.length} kugirango ukomeze',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          if (_guarantors.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Abamenyesha batowe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._guarantors.map((g) => _buildGuarantorCard(g, true)),
                ],
              ),
            ),
            const Divider(),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Hitamo abamenyesha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_guarantors.length}/3', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _availableMembers.length,
              itemBuilder: (context, index) {
                final member = _availableMembers[index];
                final isSelected = _guarantors.any((g) => g['id'] == member['id']);
                return _buildMemberCard(member, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantorCard(Map<String, dynamic> guarantor, bool canRemove) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00A86B).withOpacity(0.2),
          child: Text(guarantor['name'][0], style: const TextStyle(color: Color(0xFF00A86B), fontWeight: FontWeight.bold)),
        ),
        title: Text(guarantor['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(guarantor['phone']),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.savings, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(guarantor['shares'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        trailing: canRemove
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _removeGuarantor(guarantor['id']),
              )
            : _buildStatusBadge(guarantor['status']),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? const Color(0xFF00A86B).withOpacity(0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? const Color(0xFF00A86B) : Colors.grey[300],
          child: Text(
            member['name'][0],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(member['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member['phone']),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.savings, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(member['shares'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF00A86B))
            : ElevatedButton(
                onPressed: () => _addGuarantor(member),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Hitamo'),
              ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = {
      'pending': Colors.orange,
      'approved': Colors.green,
      'rejected': Colors.red,
    };
    final labels = {
      'pending': 'Itegereje',
      'approved': 'Yemejwe',
      'rejected': 'Yanzwe',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors[status]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        labels[status]!,
        style: TextStyle(color: colors[status], fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
