import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder notifications – replace with real API data in PR2
    final List<Map<String, dynamic>> notifications = [
      {
        'icon': Icons.sports,
        'title': 'New batch schedule uploaded',
        'body': 'Your morning batch schedule has been updated by the coach.',
        'time': '2 hours ago',
        'unread': true,
        'color': const Color(0xFF1B3D2F),
      },
      {
        'icon': Icons.payment,
        'title': 'Fee payment due',
        'body': 'Your monthly fee for Cricket batch is due on 28 Feb 2026.',
        'time': '1 day ago',
        'unread': true,
        'color': const Color(0xFFD32F2F),
      },
      {
        'icon': Icons.event,
        'title': 'Academy Tournament – March 5',
        'body': 'Inter-batch tournament announced. Check the Events section for details.',
        'time': '3 days ago',
        'unread': false,
        'color': const Color(0xFF1565C0),
      },
      {
        'icon': Icons.videocam,
        'title': 'New training video added',
        'body': 'Coach uploaded "Footwork Drills – Advanced" to your video library.',
        'time': '5 days ago',
        'unread': false,
        'color': const Color(0xFF7B1FA2),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              "Mark all read",
              style: TextStyle(color: Color(0xFF1B3D2F), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _buildNotificationCard(n);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3D2F).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none, size: 56, color: Color(0xFF1B3D2F)),
          ),
          const SizedBox(height: 20),
          const Text(
            "All caught up!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 8),
          const Text(
            "No new notifications right now.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: n['unread'] == true ? const Color(0xFFF0F7F4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: n['unread'] == true
              ? const Color(0xFF1B3D2F).withOpacity(0.18)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (n['color'] as Color).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                n['title'] as String,
                style: TextStyle(
                  fontWeight: n['unread'] == true ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            if (n['unread'] == true)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B3D2F),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(n['body'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(n['time'] as String,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
