import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:super_sonic/modal/media_file.dart';
import 'package:super_sonic/wedgits/custom_appbar.dart';
import 'package:super_sonic/wedgits/scan_debug_screen.dart';

import '../utils/theme.dart';

class LibraryScreen extends StatelessWidget {
  final List<MediaFile> audioFiles;
  final List<MediaFile> videoFiles;
  final VoidCallback onRefresh;

  const LibraryScreen({
    super.key,
    required this.audioFiles,
    required this.videoFiles,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomAppBar(
          title: 'Library',
          onRefresh: onRefresh,
          istrue: true,
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.music_note,
                        count: audioFiles.length,
                        label: 'Audio Files',
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.videocam,
                        count: videoFiles.length,
                        label: 'Video Files',
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildActionTile(
                  icon: Icons.refresh,
                  title: 'Rescan Media Files',
                  subtitle: 'Comprehensive scan for all audio and video files',
                  color: AppTheme.primaryGreen,
                  onTap: onRefresh,
                ),
                
                const SizedBox(height: 16),
                
                _buildActionTile(
                  icon: Icons.bug_report,
                  title: 'Debug Scanner',
                  subtitle: 'Test scanner and see detailed results',
                  color: Colors.orange,
                  onTap: () => _showDebugDialog(context),
                ),
                
                const SizedBox(height: 16),
                
                _buildActionTile(
                  icon: Icons.settings,
                  title: 'App Settings',
                  subtitle: 'Configure app preferences',
                  color: Colors.blue,
                  onTap: () => openAppSettings(),
                ),
                
                const SizedBox(height: 32),
                
                // File Locations Info
                const Text(
                  'Scanned Locations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildLocationInfo(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white70),
      ),
      onTap: onTap,
    );
  }

  Widget _buildLocationInfo() {
    final locations = [
      'Music, Downloads, DCIM folders',
      'WhatsApp, Telegram media',
      'App-specific directories',
      'Recording app folders',
      'Cloud storage sync folders',
      'Browser download folders',
      'System-wide file traversal',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The app scans these locations:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...locations.map((location) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.folder,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ScanDebugDialog(),
    );
  }
}
