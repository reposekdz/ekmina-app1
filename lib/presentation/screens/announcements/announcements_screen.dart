import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String userId;
  final bool isAdmin;
  
  const AnnouncementsScreen({super.key, required this.groupId, required this.userId, this.isAdmin = false});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  List<dynamic> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getAnnouncements(widget.groupId);
      if (mounted) {
        setState(() {
          _announcements = response['announcements'] ?? [];
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

  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String priority = 'NORMAL';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Itangazo rishya', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Umutwe', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(labelText: 'Ubutumwa', border: OutlineInputBorder()),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Urwego rw\'ibanze', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'LOW', child: Text('Gito')),
                    DropdownMenuItem(value: 'NORMAL', child: Text('Bisanzwe')),
                    DropdownMenuItem(value: 'HIGH', child: Text('Kinini')),
                    DropdownMenuItem(value: 'URGENT', child: Text('Byihutirwa')),
                  ],
                  onChanged: (value) => setDialogState(() => priority = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hagarika')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || messageController.text.isEmpty) return;
                try {
                  final api = ref.read(apiClientProvider);
                  await api.createAnnouncement({
                    'groupId': widget.groupId,
                    'title': titleController.text,
                    'content': messageController.text,
                    'priority': priority,
                    'createdBy': widget.userId
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _loadAnnouncements();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Itangazo ryoherejwe neza!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ErrorHandler.handleError(e)), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Ohereza'),
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
        title: const Text('Amatangazo y\'itsinda', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAnnouncements)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAnnouncements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) => _buildAnnouncementCard(_announcements[index]),
                  ),
                ),
      floatingActionButton: widget.isAdmin ? FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Itangazo'),
        backgroundColor: AppTheme.primaryGreen,
      ) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Nta matangazo arahari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (widget.isAdmin)
            TextButton(onPressed: _showCreateDialog, child: const Text('Tanga itangazo rya mbere')),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(dynamic announcement) {
    final priority = announcement['priority'] as String?;
    Color priorityColor;
    IconData priorityIcon;

    switch (priority) {
      case 'URGENT': priorityColor = Colors.red; priorityIcon = Icons.priority_high; break;
      case 'HIGH': priorityColor = Colors.orange; priorityIcon = Icons.warning; break;
      case 'LOW': priorityColor = Colors.blue; priorityIcon = Icons.info_outline; break;
      default: priorityColor = AppTheme.primaryGreen; priorityIcon = Icons.campaign;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: priorityColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(priorityIcon, color: priorityColor, size: 16),
                const SizedBox(width: 8),
                Text(priority ?? 'NORMAL', style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold, fontSize: 10)),
                const Spacer(),
                Text(Formatters.formatDate(DateTime.parse(announcement['createdAt'])),
                  style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(announcement['title'] ?? 'Nta mutwe',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(announcement['content'] ?? announcement['message'] ?? '',
                  style: TextStyle(color: Colors.grey[800], height: 1.5)),
                const Divider(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, size: 14, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(announcement['author']?['name'] ?? 'Ubuyobozi',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
