import 'package:flutter/material.dart';
import '../../../core/services/kyc_service.dart';
import '../../../data/remote/api_client.dart';
import 'kyc_verification_screen.dart';

class KYCStatusScreen extends StatefulWidget {
  const KYCStatusScreen({Key? key}) : super(key: key);

  @override
  State<KYCStatusScreen> createState() => _KYCStatusScreenState();
}

class _KYCStatusScreenState extends State<KYCStatusScreen> {
  final _kycService = KYCService(ApiClient());
  bool _isLoading = true;
  Map<String, dynamic>? _kycData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKYCStatus();
  }

  Future<void> _loadKYCStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _kycService.getKYCStatus();
      setState(() {
        _kycData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToVerification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KYCVerificationScreen(),
      ),
    );

    if (result == true) {
      _loadKYCStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Umwirondoro (KYC)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadKYCStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _kycData == null || _kycData!['verification'] == null
                  ? _buildNoKYC()
                  : _buildKYCStatus(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadKYCStatus,
              child: const Text('Ongera ugerageze'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoKYC() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 80, color: Colors.blue[700]),
            const SizedBox(height: 24),
            const Text(
              'Emeza Umwirondoro Wawe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kwemeza umwirondoro (KYC) bigufasha:\n\n'
              '• Gukora ibikorwa binini\n'
              '• Kongera umutekano wa konti yawe\n'
              '• Kwemererwa gusaba inguzanyo nini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToVerification,
              icon: const Icon(Icons.upload_file),
              label: const Text('Tangira Kwemeza'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKYCStatus() {
    final verification = _kycData!['verification'];
    final status = verification['status'];
    final documentType = verification['documentType'];
    final documentNumber = verification['documentNumber'];
    final submittedAt = DateTime.parse(verification['submittedAt']);
    final verifiedAt = verification['verifiedAt'] != null
        ? DateTime.parse(verification['verifiedAt'])
        : null;
    final rejectionReason = verification['rejectionReason'];

    final statusColor = Color(int.parse(
      _kycService.getKYCStatusColor(status).replaceAll('#', '0xFF'),
    ));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: statusColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    status == 'VERIFIED'
                        ? Icons.check_circle
                        : status == 'REJECTED'
                            ? Icons.cancel
                            : Icons.pending,
                    size: 64,
                    color: statusColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _kycService.getKYCStatusText(status, 'rw'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status == 'PENDING'
                        ? 'Umwirondoro wawe urareba. Uzahabwa ubutumwa vuba.'
                        : status == 'VERIFIED'
                            ? 'Umwirondoro wawe wemejwe neza!'
                            : 'Umwirondoro wawe wanze. Reba impamvu hasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amakuru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Ubwoko',
                    _kycService.getDocumentTypeText(documentType, 'rw'),
                  ),
                  _buildInfoRow('Nomero', documentNumber),
                  _buildInfoRow(
                    'Yoherejwe',
                    '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}',
                  ),
                  if (verifiedAt != null)
                    _buildInfoRow(
                      'Yemejwe',
                      '${verifiedAt.day}/${verifiedAt.month}/${verifiedAt.year}',
                    ),
                ],
              ),
            ),
          ),
          if (status == 'REJECTED' && rejectionReason != null) ...[
            const SizedBox(height: 24),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Impamvu yo kwanga',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(rejectionReason),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToVerification,
              icon: const Icon(Icons.refresh),
              label: const Text('Ongera Wohereze'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
          if (status == 'PENDING') ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Igihe cyo kureba: 1-3 iminsi y\'akazi',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
