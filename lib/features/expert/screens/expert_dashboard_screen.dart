import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/expert/services/expert_service.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class ExpertDashboardScreen extends StatefulWidget {
  final LocalStorageService storage;
  const ExpertDashboardScreen({super.key, required this.storage});

  @override
  State<ExpertDashboardScreen> createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> {
  late final ExpertService _expertService;
  late Future<List<dynamic>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _expertService = ExpertService(widget.storage);
    _sessionsFuture = _expertService.getMySessions();
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Expert Dashboard', 
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 24)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.logout_rounded, color: AppColors.purple),
              onPressed: () async {
                await widget.storage.clearAuthTokens();
                if (mounted) context.go('/splash');
              },
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: () async {
          setState(() {
            _sessionsFuture = _expertService.getMySessions();
          });
        },
        child: FutureBuilder<List<dynamic>>(
          future: _sessionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.purple));
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.purple),
                      ),
                      const SizedBox(height: 24),
                      const Text('Patiently Waiting', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 12),
                      const Text('You don\'t have any active consultations yet. Once a user reaches out, they will appear here.', 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.5)),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _sessionsFuture = _expertService.getMySessions();
                        }),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh Dashboard'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.purple),
                      ),
                    ],
                  ),
                ),
              );
            }

            final sessions = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final user = session['user'] ?? {};
                final profile = user['profile'] ?? {};
                final userName = (profile['displayName'] != null && profile['displayName'].isNotEmpty)
                    ? profile['displayName']
                    : 'Anonymous User';
                
                final messages = session['messages'] as List?;
                final lastMsg = (messages != null && messages.isNotEmpty) 
                    ? messages[0]['content'] 
                    : 'Consultation started';
                final lastTime = (messages != null && messages.isNotEmpty)
                    ? _formatTime(messages[0]['createdAt'])
                    : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.purple.withOpacity(0.1), AppColors.purple.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            userName.substring(0, 1).toUpperCase(),
                            style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              userName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((session['unreadCount'] ?? 0) > 0)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.purple,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                session['unreadCount'].toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('ACTIVE', 
                              style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lastMsg, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.textMedium, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(lastTime, style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                          ],
                        ),
                      ),
                      onTap: () {
                        context.push('/expert/chat/${session['id']}', extra: {'expertName': userName});
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
