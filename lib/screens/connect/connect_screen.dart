import 'package:flutter/material.dart';
import 'peerline_tab.dart';
import '../../core/theme/app_theme.dart';

/// ConnectScreen
/// Dedicated 1-on-1 PeerLine peer mentoring and support connection module.
class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PeerLineTab(),
      ),
    );
  }
}
