import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/error_handler.dart';

class LoginHistoryScreen extends ConsumerStatefulWidget {
  final String userId;
  const LoginHistoryScreen({super.key, required this.userId});

  @override
  ConsumerState<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends ConsumerState<LoginHistoryScreen> {
  List<dynamic> _loginHistory = [];
  bool _loading = true;
  String _filter = 'all'; // all, success, failed, suspicious

  @override
  void initState() {
    super.initState();
    _loadLoginHistory();
  }

  Future<void> _loadLoginHistory() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/users/${widget.userId}/login-history');
      
      if (mounted) {
        setState(() {
          _loginHistory = response['history'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<dynamic> get _filteredHistory {
    if (_filter == 'all') return _loginHistory;
    if (_filter == 'success') return _loginHistory.where((h) => h['status'] == 'SUCCESS').toList();
    if (_filter == 'failed') return _loginHistory.where((h) => h['status'] == 'FAILED').toList();
    if (_filter == 'suspicious') return _loginHistory.where((h) => h['suspicious'] == true).toList();
    return _loginHistory;
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getDeviceIcon(String? deviceType) {
    switch (deviceType?.toLowerCase()) {
      case 'mobile':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet;
      case 'desktop':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'BLOCKED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amateka yo kwinjira'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLoginHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadLoginHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredHistory.length,
                          itemBuilder: (context, index) => _buildLoginItem(_filteredHistory[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Byose', 'all', Icons.list),
            const SizedBox(width: 8),
            _buildFilterChip('Byatsinze', 'success', Icons.check_circle),
            const SizedBox(width: 8),
            _buildFilterChip('Byanze', 'failed', Icons.cancel),
            const SizedBox(width: 8),
            _buildFilterChip('Bikekwa', 'suspicious', Icons.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF00A86B)),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
      },
      selectedColor: const Color(0xFF00A86B),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF00A86B)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nta mateka yo kwinjira',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginItem(Map<String, dynamic> login) {
    final status = login['status'] ?? 'UNKNOWN';
    final isSuspicious = login['suspicious'] == true;
    final deviceType = login['deviceType'];
    final deviceName = login['deviceName'] ?? 'Unknown Device';
    final ipAddress = login['ipAddress'] ?? 'Unknown IP';
    final location = login['location'] ?? 'Unknown Location';
    final timestamp = login['timestamp'] ?? '';
    final failureReason = login['failureReason'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSuspicious ? 4 : 1,
      color: isSuspicious ? Colors.orange[50] : null,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getDeviceIcon(deviceType),
            color: _getStatusColor(status),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                deviceName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isSuspicious)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Bikekwa', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  status == 'SUCCESS' ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_formatDateTime(timestamp)),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.location_on, 'Aho:', location),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.language, 'IP Address:', ipAddress),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.devices, 'Telefoni:', deviceName),
                if (failureReason != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.error, 'Impamvu:', failureReason, color: Colors.red),
                ],
                if (isSuspicious) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Iyi kwinjira ikekwa. Niba atari wewe, hindura ijambo ryibanga vuba.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color ?? Colors.black87),
          ),
        ),
      ],
    );
  }
}
