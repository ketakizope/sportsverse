import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  static const List<Map<String, dynamic>> _events = [
    {
      'title': 'Inter-Batch Tournament',
      'type': 'TOURNAMENT',
      'sport': 'Cricket',
      'day': '05',
      'month': 'MAR',
      'time': '9:00 AM',
      'venue': 'Main Ground, Elite Academy',
      'color': Color(0xFFD32F2F),
      'icon': Icons.emoji_events,
    },
    {
      'title': 'Friendly Match – Blue vs Green',
      'type': 'MATCH',
      'sport': 'Badminton',
      'day': '12',
      'month': 'MAR',
      'time': '10:30 AM',
      'venue': 'Indoor Court 2',
      'color': Color(0xFF1565C0),
      'icon': Icons.sports,
    },
    {
      'title': 'Skills Assessment Day',
      'type': 'ASSESSMENT',
      'sport': 'All Sports',
      'day': '20',
      'month': 'MAR',
      'time': '8:00 AM',
      'venue': 'Academy Main Hall',
      'color': Color(0xFF7B1FA2),
      'icon': Icons.assignment_turned_in,
    },
    {
      'title': 'Season Closing Ceremony',
      'type': 'EVENT',
      'sport': 'All Sports',
      'day': '31',
      'month': 'MAR',
      'time': '6:00 PM',
      'venue': 'Elite Academy Auditorium',
      'color': Color(0xFF1B3D2F),
      'icon': Icons.celebration,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("Events & Matches",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, color: Colors.white, size: 40),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Upcoming Events", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text("${_events.length} events this month", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Schedule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _events.length,
              itemBuilder: (context, i) => _buildEventCard(_events[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> e) {
    final color = e['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Date block
          Container(
            width: 54,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(e['day'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(e['month'] as String, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(e['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e['type'] as String,
                          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(e['time'] as String, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(e['venue'] as String,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis),
                    ),
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
