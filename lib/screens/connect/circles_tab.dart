import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:infano_care_mobile/widgets/circle_card.dart';
import 'package:infano_care_mobile/widgets/age_room_section.dart';
import 'package:infano_care_mobile/widgets/community_pulse_strip.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:provider/provider.dart';

class CirclesTab extends StatefulWidget {
  const CirclesTab({Key? key}) : super(key: key);

  @override
  State<CirclesTab> createState() => _CirclesTabState();
}

class _CirclesTabState extends State<CirclesTab> with AutomaticKeepAliveClientMixin {
  late CommunityApi _api;
  late Future<List<Circle>> _circlesFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _api = Provider.of<CommunityApi>(context, listen: false);
    _load();
  }

  void _load() {
    if (!mounted) return;
    setState(() {
      debugPrint('CirclesTab: Fetching circles...');
      _circlesFuture = _api.getCircles().then((list) {
        debugPrint('CirclesTab: Loaded ${list.length} circles');
        return list;
      }).catchError((e) {
        debugPrint('CirclesTab: Error loading circles: $e');
        throw e;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Circle>>(
      future: _circlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('CirclesTab Error: ${snapshot.error}');
          if (snapshot.stackTrace != null) {
            debugPrint('CirclesTab StackTrace: ${snapshot.stackTrace}');
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Could not load circles', style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => setState(_load), child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        final allCircles = snapshot.data ?? [];
        // Spec: topic circles (not age-specific) in the main grid
        final topicCircles = allCircles.where((c) => !c.isAgeSpecific).toList();

        return RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Topic Circles Label ───────────────────────────────────
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Topic Circles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ),

              // ── 3×3 Grid ─────────────────────────────────────────────
              if (topicCircles.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade200),
                        const SizedBox(height: 12),
                        Text('No circles found for your tier', style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 columns on narrow screens
                      mainAxisExtent: 120, // Increased height: 120dp
                      crossAxisSpacing: 10, // Gap: 10dp
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => CircleCard(circle: topicCircles[index]),
                      childCount: topicCircles.length,
                    ),
                  ),
                ),

              // ── Community Pulse Strip ──────────────────────────────────
              SliverToBoxAdapter(
                child: CommunityPulseStrip(
                  circles: allCircles.where((c) => c.unreadCount != null && c.unreadCount! > 0).toList(),
                ),
              ),

              // ── Age Room Section ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: AgeRoomSection(circles: allCircles),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
