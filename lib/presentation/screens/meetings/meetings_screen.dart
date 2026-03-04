import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class MeetingsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String userId;
  final bool isAdmin;
  
  const MeetingsScreen({super.key, required this.groupId, required this.userId, this.isAdmin = false});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  List<dynamic> _meetings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getMeetings(widget.groupId);
      if (mounted) {
        setState(() {
          _meetings = response['meetings'] ?? [];
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

  Future<void> _markAttendance(String meetingId) async {
    try {
      final api = ref.read(apiClientProvider);
      // Assuming a membershipId is needed, would normally come from context or previous screen
      // For now using userId as a placeholder if membershipId isn't easily available
      await api.markAttendance(meetingId, widget.userId);
      _loadMeetings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wemeje ko witabiriye inama!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showCreateMeetingDialog() async {
    final titleController = TextEditingController();
    final agendaController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Gupanga Inama Nshya', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Umutwe w\'inama')),
                const SizedBox(height: 12),
                TextField(controller: agendaController, decoration: const InputDecoration(labelText: 'Ibigomba kuganirwaho'), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Aho inama izabera')),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Itariki n\'Igihe'),
                  subtitle: Text('${Formatters.formatDate(selectedDate)} saa ${selectedTime.format(context)}'),
                  trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                    if (date != null) {
                      final time = await showTimePicker(context: context, initialTime: selectedTime);
                      if (time != null) {
                        setDialogState(() {
                          selectedDate = date;
                          selectedTime = time;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                final dt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                try {
                  final api = ref.read(apiClientProvider);
                  await api.createMeeting({
                    'groupId': widget.groupId,
                    'title': titleController.text,
                    'agenda': agendaController.text,
                    'location': locationController.text,
                    'meetingDate': dt.toIso8601String(),
                    'createdBy': widget.userId,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _loadMeetings();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.handleError(e))));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Bika'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inama z\'itsinda', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMeetings)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _meetings.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMeetings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _meetings.length,
                    itemBuilder: (context, index) => _buildMeetingCard(_meetings[index]),
                  ),
                ),
      floatingActionButton: widget.isAdmin ? FloatingActionButton.extended(
        onPressed: _showCreateMeetingDialog,
        icon: const Icon(Icons.add),
        label: const Text('Panga Inama'),
        backgroundColor: AppTheme.primaryGreen,
      ) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Nta nama ziteganyijwe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (widget.isAdmin)
            TextButton(onPressed: _showCreateMeetingDialog, child: const Text('Panga inama ya mbere')),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(dynamic meeting) {
    final date = DateTime.parse(meeting['meetingDate']);
    final isPast = date.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: isPast ? Colors.grey.shade200 : AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPast ? Colors.grey.shade100 : AppTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(isPast ? Icons.event_available : Icons.event,
            color: isPast ? Colors.grey : AppTheme.primaryGreen),
        ),
        title: Text(meeting['title'] ?? 'Inama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(Formatters.formatDateTime(date), style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(meeting['location'] ?? 'Aho batavuze', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text('Ibigomba kuganirwaho:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(meeting['agenda'] ?? 'Nta birambuye', style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                const SizedBox(height: 16),
                if (!isPast)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _markAttendance(meeting['id']),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('EMEZA KO UZAZA'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                    ),
                  ),
                if (isPast && meeting['attendance'] != null) ...[
                  const Text('Abatabiriye:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildAttendanceList(meeting['attendance']),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<dynamic> attendance) {
    return Wrap(
      spacing: 8,
      children: attendance.map((a) => Chip(
        avatar: CircleAvatar(child: Text(a['user']?['name']?[0] ?? 'U', style: const TextStyle(fontSize: 10))),
        label: Text(a['user']?['name'] ?? 'Umuntu', style: const TextStyle(fontSize: 10)),
        backgroundColor: Colors.grey.shade100,
      )).toList(),
    );
  }
}
