import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class DataRightsPrivacyScreen extends StatefulWidget {
  const DataRightsPrivacyScreen({super.key});

  @override
  State<DataRightsPrivacyScreen> createState() => _DataRightsPrivacyScreenState();
}

class _DataRightsPrivacyScreenState extends State<DataRightsPrivacyScreen> {
  bool _isExporting = false;

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final res = await ApiService.instance.dio.post('/api/v1/tracker/data/export');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? 'Export initiated. You will receive an email shortly.'),
            backgroundColor: AppColors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export data: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _deleteData() async {
    // Stage 1 Confirmation
    final confirmed1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tracker Data?'),
        content: const Text('This will permanently delete all your cycle logs, predictions, and symptom history. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Proceed', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed1 != true) return;

    // Stage 2 Confirmation / Mock Biometric
    if (!mounted) return;
    final confirmed2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text('To verify it is you, please confirm you want to permanently erase this health data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Erase Data'),
          ),
        ],
      ),
    );

    if (confirmed2 != true) return;

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await ApiService.instance.dio.delete('/api/v1/tracker/data/all');
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All health data has been permanently erased.'), backgroundColor: Colors.green),
        );
        // Navigate back to home or tracker onboarding
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete data: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Health Data Privacy', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.pink, size: 60),
          const SizedBox(height: 16),
          Text(
            'Your Data Belongs To You',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'We believe your health data should be private, secure, and entirely under your control.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textMedium),
          ),
          const SizedBox(height: 48),

          Text('Privacy Security Status', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
          const SizedBox(height: 16),
          _buildSecurityCheck('Daily note encryption (AES-256)'),
          _buildSecurityCheck('Isolated health database cluster'),
          _buildSecurityCheck('Zero analytics access to health data'),
          _buildSecurityCheck('No third-party advertising sharing'),
          _buildSecurityCheck('Voice notes stored device-local only'),
          
          const SizedBox(height: 48),
          
          Text('Data Rights Actions', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.download_rounded, color: AppColors.purple),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Export All Health Data', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark))),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Get a copy of your cycle logs, predictions, and reports in a ZIP format.', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMedium)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isExporting ? null : _exportData,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.purple,
                      side: const BorderSide(color: AppColors.purple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isExporting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple))
                      : const Text('Export Data'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red[100]!),
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Erase Tracker Data', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.error))),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Permanently delete all cycle history and predictions. This cannot be undone and any prediction accuracy will be lost.', style: GoogleFonts.nunito(fontSize: 14, color: Colors.red[700])),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _deleteData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Erase All Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSecurityCheck(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textMedium))),
        ],
      ),
    );
  }
}
