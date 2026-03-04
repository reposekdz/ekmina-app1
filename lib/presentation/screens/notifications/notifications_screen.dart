import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _notifications = [];
  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final storage = SecureStorageService();
      _userId = await storage.getUserId();
      if (_userId == null) return;

      final api = ref.read(apiClientProvider);
      final response = await api.getNotifications(_userId!);
      
      if (mounted) {
        setState(() {
          _notifications = response['notifications'] ?? [];
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

  Future<void> _markAsRead(String id) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.markNotificationRead(id);
      _loadNotifications();
    } catch (e) {
      // Silent error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integuza', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Zishya'),
            Tab(text: 'Zasomwe'),
            Tab(text: 'Zose'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNotifications),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(unreadOnly: true),
                _buildNotificationList(readOnly: true),
                _buildNotificationList(),
              ],
            ),
    );
  }

  Widget _buildNotificationList({bool unreadOnly = false, bool readOnly = false}) {
    final filtered = _notifications.where((n) {
      if (unreadOnly) return n['read'] == false;
      if (readOnly) return n['read'] == true;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(unreadOnly ? 'Nta nteguza nshya uhite' : 'Nta nteguza zihari',
              style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final n = filtered[index];
          return _buildNotificationItem(n);
        },
      ),
    );
  }

  Widget _buildNotificationItem(dynamic n) {
    final bool isRead = n['read'] ?? false;
    final type = n['type'] as String?;

    IconData icon;
    Color color;

    switch (type) {
      case 'LOAN_APPROVED':
      case 'LOAN_REJECTED': icon = Icons.request_quote; color = AppTheme.accentBlue; break;
      case 'PAYMENT_RECEIVED': icon = Icons.payment; color = AppTheme.primaryGreen; break;
      case 'GROUP_INVITATION': icon = Icons.group_add; color = AppTheme.secondaryGold; break;
      case 'MEETING_REMINDER': icon = Icons.event; color = Colors.orange; break;
      default: icon = Icons.notifications; color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isRead ? Colors.grey.shade100 : AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: () {
          if (!isRead) _markAsRead(n['id']);
          _handleNotificationClick(n);
        },
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(n['title'] ?? 'Integuza',
          style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(n['message'] ?? '', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            const SizedBox(height: 4),
            Text(Formatters.formatDateTime(DateTime.parse(n['createdAt'])),
              style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
        trailing: !isRead ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle)) : null,
      ),
    );
  }

  void _handleNotificationClick(dynamic n) {
    final type = n['type'] as String?;
    final data = n['data'] as Map<String, dynamic>?;

    if (type?.startsWith('LOAN') == true) {
      context.push('/loans');
    } else if (type?.startsWith('GROUP') == true && data?['groupId'] != null) {
      context.push('/groups/${data!['groupId']}');
    } else if (type?.startsWith('PAYMENT') == true) {
      context.push('/wallet');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
