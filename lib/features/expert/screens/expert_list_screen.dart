import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/expert/services/expert_service.dart';
import 'package:get_it/get_it.dart';

class ExpertListScreen extends StatefulWidget {
  final LocalStorageService storage;
  const ExpertListScreen({super.key, required this.storage});

  @override
  State<ExpertListScreen> createState() => _ExpertListScreenState();
}

class _ExpertListScreenState extends State<ExpertListScreen> {
  late final ExpertService _expertService;
  late Future<List<dynamic>> _expertsFuture;

  @override
  void initState() {
    super.initState();
    _expertService = ExpertService(widget.storage);
    _expertsFuture = _expertService.getExperts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk to an Expert'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _expertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No experts available right now.', 
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _expertsFuture = _expertService.getExperts();
                    }),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final experts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: experts.length,
            itemBuilder: (context, index) {
              final expert = experts[index];
              final profile = expert['profile'] ?? {};
              final name = (profile['displayName'] != null && profile['displayName'].isNotEmpty) 
                  ? profile['displayName'] 
                  : 'Expert Helper';
              final pronouns = profile['pronouns'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: Theme.of(context).primaryColor, size: 32),
                  ),
                  title: Text(name, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(pronouns.isNotEmpty ? pronouns : 'Verified Expert'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((expert['unreadCount'] ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            expert['unreadCount'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () async {
                    final session = await _expertService.getOrCreateSession(expert['id']);
                    if (session != null && mounted) {
                      context.push('/expert/chat/${session['id']}', extra: {'expertName': name});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
