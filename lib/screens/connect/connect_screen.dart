import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'circles_tab.dart';
import 'peerline_tab.dart';
import 'events_tab.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({Key? key}) : super(key: key);

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back arrow
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(
          'Connect',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E), // Custom dark color
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16, // 32dp circle = 16 radius
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, size: 20, color: Colors.grey),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 2,
          indicatorColor: Colors.pink, // pink underline indicator
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
          ),
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(
              text: '🌐 Circles',
            ),
            Tab(
              text: '💜 PeerLine',
            ),
            Tab(
              text: '📅 Events',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CirclesTab(),
          PeerLineTab(),
          EventsTab(),
        ],
      ),
    );
  }
}
