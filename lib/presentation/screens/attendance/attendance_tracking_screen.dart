import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

class AttendanceTrackingScreen extends StatefulWidget {
  final String meetingId;
  final bool isOrganizer;
  const AttendanceTrackingScreen({super.key, required this.meetingId, this.isOrganizer = false});

  @override
  State<AttendanceTrackingScreen> createState() => _AttendanceTrackingScreenState();
}

class _AttendanceTrackingScreenState extends State<AttendanceTrackingScreen> {
  final List<Map<String, dynamic>> _attendees = [
    {'name': 'Jean Uwimana', 'status': 'present', 'time': '09:00', 'avatar': 'J'},
    {'name': 'Marie Mukamana', 'status': 'present', 'time': '09:05', 'avatar': 'M'},
    {'name': 'Paul Habimana', 'status': 'late', 'time': '09:30', 'avatar': 'P'},
    {'name': 'Grace Uwase', 'status': 'absent', 'time': null, 'avatar': 'G'},
  ];

  int get _presentCount => _attendees.where((a) => a['status'] == 'present').length;
  int get _lateCount => _attendees.where((a) => a['status'] == 'late').length;
  int get _absentCount => _attendees.where((a) => a['status'] == 'absent').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kwitabira inama'),
        actions: [
          if (widget.isOrganizer)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportAttendance,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          _buildTabBar(),
          Expanded(child: _buildAttendeesList()),
        ],
      ),
      floatingActionButton: widget.isOrganizer
          ? FloatingActionButton.extended(
              onPressed: _showQRCode,
              icon: const Icon(Icons.qr_code),
              label: const Text('QR Code'),
            )
          : FloatingActionButton.extended(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan'),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A86B), Color(0xFF00C853)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Inama y\'Ikimina',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, dd MMMM yyyy • HH:mm').format(DateTime.now()),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Bahari', _presentCount.toString(), Icons.check_circle),
              _buildStatItem('Batinze', _lateCount.toString(), Icons.access_time),
              _buildStatItem('Ntibari', _absentCount.toString(), Icons.cancel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabChip('Bose (${_attendees.length})', true),
          const SizedBox(width: 8),
          _buildTabChip('Bahari ($_presentCount)', false),
          const SizedBox(width: 8),
          _buildTabChip('Ntibari ($_absentCount)', false),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {},
    );
  }

  Widget _buildAttendeesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendees.length,
      itemBuilder: (context, index) {
        final attendee = _attendees[index];
        return _buildAttendeeCard(attendee);
      },
    );
  }

  Widget _buildAttendeeCard(Map<String, dynamic> attendee) {
    final statusColors = {
      'present': Colors.green,
      'late': Colors.orange,
      'absent': Colors.red,
    };
    final statusLabels = {
      'present': 'Yahari',
      'late': 'Yatinze',
      'absent': 'Ntiyari',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColors[attendee['status']]!.withOpacity(0.2),
          child: Text(
            attendee['avatar'],
            style: TextStyle(
              color: statusColors[attendee['status']],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(attendee['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: attendee['time'] != null
            ? Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Yinjiye saa ${attendee['time']}'),
                ],
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColors[attendee['status']]!.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusLabels[attendee['status']]!,
            style: TextStyle(
              color: statusColors[attendee['status']],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan kugirango witabire',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: 'meeting:${widget.meetingId}',
                version: QrVersions.auto,
                size: 250,
              ),
              const SizedBox(height: 24),
              Text(
                'Code: ${widget.meetingId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Funga'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _QRScannerScreen(
          onScanned: (code) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Witabiriye neza!')),
            );
          },
        ),
      ),
    );
  }

  void _exportAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Raporo yoherejwe kuri email yawe')),
    );
  }
}

class _QRScannerScreen extends StatefulWidget {
  final Function(String) onScanned;
  const _QRScannerScreen({required this.onScanned});

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    widget.onScanned(barcode.rawValue!);
                    Navigator.pop(context);
                    break;
                  }
                }
              },
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text('Shyira QR code mu kibanza'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
