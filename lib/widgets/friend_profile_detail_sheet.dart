import 'package:flutter/material.dart';
import '../models/friend_profile.dart';

class FriendProfileDetailSheet extends StatelessWidget {
  final FriendProfile profile;

  const FriendProfileDetailSheet({Key? key, required this.profile}) : super(key: key);

  static void show(BuildContext context, FriendProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FriendProfileDetailSheet(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.pink[100],
                        backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
                        child: profile.photoUrl == null
                            ? const Icon(Icons.face_retouching_natural, size: 40, color: Colors.pink)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.nickname ?? 'Anonymous',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (profile.ageBand != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      profile.ageBand!,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  profile.locationLabel ?? 'Nearby',
                                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  if (profile.compatibilityScore != null) ...[
                    _buildSectionTitle('Compatibility'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.1), Colors.pink.withOpacity(0.1)]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.pink.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                profile.compatibilityLabel ?? 'Good vibe match',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                              ),
                              Text(
                                '${profile.compatibilityScore}%',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.pink),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: profile.compatibilityScore! / 100,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionTitle('Looking For'),
                  const SizedBox(height: 16),
                  ...profile.intent.map((intent) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.track_changes, color: Colors.amber, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(intent, style: const TextStyle(fontSize: 16))),
                          ],
                        ),
                      )),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Vibes & Interests'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.vibeTags
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.w500),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 32),
                  if ((profile.sharedCircles ?? 0) > 0 || (profile.sharedEvents ?? 0) > 0) ...[
                    _buildSectionTitle('Shared Community'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if ((profile.sharedCircles ?? 0) > 0)
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.bubble_chart,
                              count: profile.sharedCircles!,
                              label: 'Shared Circles',
                              color: Colors.blue,
                            ),
                          ),
                        if ((profile.sharedCircles ?? 0) > 0 && (profile.sharedEvents ?? 0) > 0)
                          const SizedBox(width: 16),
                        if ((profile.sharedEvents ?? 0) > 0)
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.event,
                              count: profile.sharedEvents!,
                              label: 'Shared Events',
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
    );
  }

  Widget _buildStatCard({required IconData icon, required int count, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
