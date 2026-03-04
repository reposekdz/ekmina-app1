import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.done_all), onPressed: _markAllAsRead),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF00A86B),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Groups'),
          Tab(text: 'Loans'),
          Tab(text: 'Payments'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildNotificationList('all'),
        _buildNotificationList('groups'),
        _buildNotificationList('loans'),
        _buildNotificationList('payments'),
      ],
    );
  }

  Widget _buildNotificationList(String type) {
    final notifications = [
      {
        'type': 'loan',
        'icon': Icons.request_quote,
        'color': const Color(0xFFFFB800),
        'title': 'Loan Approved',
        'message': 'Your loan of 50,000 RWF has been approved',
        'time': '2 hours ago',
        'isRead': false,
      },
      {
        'type': 'payment',
        'icon': Icons.payment,
        'color': const Color(0xFF00A86B),
        'title': 'Payment Received',
        'message': 'You received 5,000 RWF from Abahizi Kimina',
        'time': '5 hours ago',
        'isRead': false,
      },
      {
        'type': 'group',
        'icon': Icons.groups,
        'color': const Color(0xFF0066CC),
        'title': 'New Group Invitation',
        'message': 'Marie Uwase invited you to join Young Pros 2026',
        'time': '1 day ago',
        'isRead': true,
      },
      {
        'type': 'loan',
        'icon': Icons.warning,
        'color': Colors.orange,
        'title': 'Payment Due Soon',
        'message': 'Your loan payment of 10,000 RWF is due in 3 days',
        'time': '1 day ago',
        'isRead': true,
      },
      {
        'type': 'group',
        'icon': Icons.event,
        'color': const Color(0xFF00A86B),
        'title': 'Meeting Scheduled',
        'message': 'Abahizi Kimina meeting on Jan 20, 2026 at 2:00 PM',
        'time': '2 days ago',
        'isRead': true,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(
          notification['icon'] as IconData,
          notification['color'] as Color,
          notification['title'] as String,
          notification['message'] as String,
          notification['time'] as String,
          notification['isRead'] as bool,
        );
      },
    );
  }

  Widget _buildNotificationItem(IconData icon, Color color, String title, String message, String time, bool isRead) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFF00A86B).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.transparent : const Color(0xFF00A86B).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                  ),
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A86B),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
          onTap: () => _showNotificationDetail(title, message),
        ),
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _showNotificationDetail(String title, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
