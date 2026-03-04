import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/fcm_service.dart';

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
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getMeetings(widget.groupId);
      if (mounted) setState(() {
        _meetings = response['meetings'];
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createMeeting() async {
    final titleController = TextEditingController();
    final agendaController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Inama nshya'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Umutwe')),
                const SizedBox(height: 12),
                TextField(controller: agendaController, decoration: const InputDecoration(labelText: 'Ibigomba kuganirwaho'), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Aho')),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Itariki'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setDialogState(() => selectedDate = date);
                  },
                ),
                ListTile(
                  title: const Text('Igihe'),
                  subtitle: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: selectedTime);
                    if (time != null) setDialogState(() => selectedTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Andika umutwe'), backgroundColor: Colors.orange),
                  );
                  return;
                }

                try {
                  final meetingDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  final api = ref.read(apiClientProvider);
                  await api.createMeeting({
                    'groupId': widget.groupId,
                    'title': titleController.text,
                    'agenda': agendaController.text,
                    'location': locationController.text,
                    'meetingDate': meetingDateTime.toIso8601String(),
                    'duration': 120,
                    'createdBy': widget.userId,
                  });

                  await FCMService.sendNotificationToGroup(
                    groupId: widget.groupId,
                    title: 'Inama nshya',
                    body: 'Inama "${titleController.text}" izabera ku ${selectedDate.day}/${selectedDate.month}',
                    type: 'meetings',
                    data: {'meetingDate': meetingDateTime.toIso8601String()},
                  );

                  Navigator.pop(context);
                  _loadMeetings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inama yashyizweho'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ikosa: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Bika'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inama')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inama'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMeetings)],
      ),
      body: _meetings.isEmpty
          ? const Center(child: Text('Nta nama'))
          : RefreshIndicator(
              onRefresh: _loadMeetings,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _meetings.length,
                itemBuilder: (context, index) {
                  final meeting = _meetings[index];
                  final meetingDate = DateTime.parse(meeting['meetingDate']);
                  final attendance = meeting['attendance'] as List;
                  final attendanceCount = attendance.where((a) => a['status'] == 'PRESENT').length;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00A86B),
                        child: const Icon(Icons.event, color: Colors.white),
                      ),
                      title: Text(meeting['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${meetingDate.day}/${meetingDate.month}/${meetingDate.year} - ${meeting['location'] ?? 'Aho hatavuzwe'}'),
                          Text('Bitabiriye: $attendanceCount/${attendance.length}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      children: [
                        if (meeting['agenda'] != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(meeting['agenda'], style: const TextStyle(color: Colors.grey)),
                          ),
                        const Divider(),
                        ...attendance.map((a) => ListTile(
                          dense: true,
                          leading: Icon(
                            a['status'] == 'PRESENT' ? Icons.check_circle : Icons.cancel,
                            color: a['status'] == 'PRESENT' ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          title: Text(a['membership']['user']['name'], style: const TextStyle(fontSize: 14)),
                          trailing: a['checkInTime'] != null
                              ? Text(
                                  '${DateTime.parse(a['checkInTime']).hour.toString().padLeft(2, '0')}:${DateTime.parse(a['checkInTime']).minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 11),
                                )
                              : null,
                        )),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _createMeeting,
              backgroundColor: const Color(0xFF00A86B),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
