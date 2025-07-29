import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:super_sonic/modal/media_file.dart';
import 'package:super_sonic/wedgits/custom_appbar.dart';
import 'package:super_sonic/wedgits/media_list_tile.dart';

import '../services/audio_player_service.dart';

import '../utils/theme.dart';

class MusicScreen extends StatelessWidget {
  final List<MediaFile> audioFiles;
  final VoidCallback onRefresh;
  final String statusMessage;

  const MusicScreen({
    super.key,
    required this.audioFiles,
    required this.onRefresh,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomAppBar(
          title: 'Music',
          onRefresh: onRefresh,
        ),
        
        // Status message
        if (statusMessage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppTheme.primaryGreen.withOpacity(0.1),
            child: Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Music List
        Expanded(
          child: audioFiles.isEmpty
              ? _buildEmptyState()
              : _buildMusicList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          Text(
            'No Music Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add some music files to your device and tap the refresh button',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 200),
      itemCount: audioFiles.length,
      itemBuilder: (context, index) {
        final audioFile = audioFiles[index];
        
        return StreamBuilder<PlayerState>(
          stream: AudioPlayerService().audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final isCurrentTrack = AudioPlayerService().currentTrack?.path == audioFile.path;
            final isPlaying = snapshot.data?.playing ?? false;
            
            return MediaListTile(
              mediaFile: audioFile,
              isCurrentTrack: isCurrentTrack,
              isPlaying: isPlaying && isCurrentTrack,
              onTap: () => _playTrack(index),
            );
          },
        );
      },
    );
  }

  Future<void> _playTrack(int index) async {
    try {
      await AudioPlayerService().playTrack(index);
    } catch (e) {
      print('Error playing track: $e');
    }
  }
}
