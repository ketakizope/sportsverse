import 'package:flutter/material.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  // Placeholder video data – replace with real API call in PR2
  static const List<Map<String, dynamic>> _videos = [
    {
      'title': 'Footwork Drills – Advanced',
      'coach': 'Coach Rahul',
      'duration': '12:34',
      'sport': 'Badminton',
      'date': 'Feb 20, 2026',
      'thumbnail': Icons.sports_tennis,
      'color': Color(0xFF1B3D2F),
    },
    {
      'title': 'Serve Technique Masterclass',
      'coach': 'Coach Priya',
      'duration': '08:15',
      'sport': 'Tennis',
      'date': 'Feb 16, 2026',
      'thumbnail': Icons.sports,
      'color': Color(0xFF1565C0),
    },
    {
      'title': 'Warm-up Routine – Pre Match',
      'coach': 'Coach Arjun',
      'duration': '05:48',
      'sport': 'Cricket',
      'date': 'Feb 10, 2026',
      'thumbnail': Icons.sports_cricket,
      'color': Color(0xFF7B1FA2),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          "Training Videos",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
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
          // Header banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B3D2F), Color(0xFF2D6A4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Video Library", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 4),
                    Text("Watch training videos from your coaches", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Recent Videos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _videos.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _videos.length,
                    itemBuilder: (context, index) => _buildVideoCard(_videos[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 90,
            height: 80,
            decoration: BoxDecoration(
              color: (v['color'] as Color).withOpacity(0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(v['thumbnail'] as IconData, color: v['color'] as Color, size: 36),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(v['coach'] as String, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (v['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(v['sport'] as String,
                            style: TextStyle(fontSize: 10, color: v['color'] as Color, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(v['duration'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Play arrow
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.play_circle_outline, color: v['color'] as Color, size: 28),
          ),
        ],
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
            child: const Icon(Icons.video_library_outlined, size: 56, color: Color(0xFF1B3D2F)),
          ),
          const SizedBox(height: 20),
          const Text("No videos yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Your coach hasn't uploaded any videos yet.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
