import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/fraud_warning_widget.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  final String transactionId;
  const TransactionDetailsScreen({super.key, required this.transactionId});

  @override
  ConsumerState<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends ConsumerState<TransactionDetailsScreen> {
  Map<String, dynamic>? _transaction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/transactions/${widget.transactionId}');
      if (mounted) setState(() {
        _transaction = response['transaction'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(appBar: AppBar(title: const Text('Ibisobanuro')), body: const Center(child: CircularProgressIndicator()));
    if (_transaction == null) return Scaffold(appBar: AppBar(title: const Text('Ibisobanuro')), body: const Center(child: Text('Nta makuru')));

    final type = _transaction!['type'];
    final isCredit = ['DEPOSIT', 'TRANSFER_IN', 'LOAN_DISBURSEMENT'].contains(type);

    return Scaffold(
      appBar: AppBar(title: const Text('Ibisobanuro'), actions: [
        IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        IconButton(icon: const Icon(Icons.download), onPressed: () {}),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, size: 64, color: isCredit ? Colors.green : Colors.red),
                  const SizedBox(height: 16),
                  Text('${isCredit ? '+' : '-'}${Formatters.formatCurrency(_transaction!['amount'].toDouble())}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isCredit ? Colors.green : Colors.red)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _getStatusColor(_transaction!['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Text(_transaction!['status'], style: TextStyle(color: _getStatusColor(_transaction!['status']), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_transaction!['fraudRisk'] != null && _transaction!['fraudRisk'] != 'LOW')
            FraudWarningWidget(riskLevel: _transaction!['fraudRisk'], message: 'Igikorwa gikekwa'),
          const SizedBox(height: 16),
          _buildDetailCard('Ibisobanuro', [
            _buildDetailRow('Ubwoko', _getTypeText(type)),
            _buildDetailRow('Nimero', _transaction!['reference'] ?? 'N/A'),
            _buildDetailRow('Itariki', Formatters.formatDateTime(DateTime.parse(_transaction!['createdAt']))),
            if (_transaction!['provider'] != null) _buildDetailRow('Uburyo', _transaction!['provider']),
            if (_transaction!['description'] != null) _buildDetailRow('Ibisobanuro', _transaction!['description']),
          ]),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'FAILED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'DEPOSIT': return 'Kwinjiza';
      case 'WITHDRAWAL': return 'Gusohora';
      case 'TRANSFER_IN': return 'Amafaranga yinjiye';
      case 'TRANSFER_OUT': return 'Amafaranga yasohowe';
      default: return type;
    }
  }
}
