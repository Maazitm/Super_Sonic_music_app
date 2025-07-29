import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:super_sonic/Appcolor/colors.dart';
import 'package:super_sonic/modal/media_file.dart';
import 'package:super_sonic/services/video_service.dart';
import 'package:super_sonic/wedgits/custom_appbar.dart';
import 'package:super_sonic/wedgits/video_bottom_navigation.dart';
import 'package:super_sonic/wedgits/video_list_tile.dart';

import '../utils/theme.dart';

class VideoScreen extends StatefulWidget {
  final List<MediaFile> videoFiles;
  final VoidCallback onRefresh;
  final String statusMessage;

  const VideoScreen({
    super.key,
    required this.videoFiles,
    required this.onRefresh,
    required this.statusMessage,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final VideoService _videoService = VideoService();

  @override
  void initState() {
    super.initState();
    _initializeVideoService();
  }

  Future<void> _initializeVideoService() async {
    await _videoService.initialize();
    if (widget.videoFiles.isNotEmpty) {
      await _videoService.setVideoPlaylist(widget.videoFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomAppBar(
          title: 'Videos',
          onRefresh: widget.onRefresh,
        ),
        
        // Status message
        if (widget.statusMessage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppTheme.primaryGreen.withOpacity(0.1),
            child: Text(
              widget.statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Video List
        Expanded(
          child: widget.videoFiles.isEmpty
              ? _buildEmptyState()
              : _buildVideoList(),
        ),

        // Video Bottom Player (only show when video audio is playing)
        StreamBuilder<PlayerState>(
          stream: _videoService.audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            if (_videoService.currentVideo != null) {
              return const VideoBottomPlayer();
            }
            return const SizedBox.shrink();
          },
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
            Icons.video_library,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          Text(
            'No Videos Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add some video files to your device and tap the refresh button',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 180), // Space for bottom player
      itemCount: widget.videoFiles.length,
      itemBuilder: (context, index) {
        final videoFile = widget.videoFiles[index];
        
        return StreamBuilder<PlayerState>(
          stream: _videoService.audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final isCurrentVideo = _videoService.currentVideo?.path == videoFile.path;
            final isPlaying = snapshot.data?.playing ?? false;
            
            return VideoListTile(
              videoFile: videoFile,
              isCurrentVideo: isCurrentVideo,
              isPlaying: isPlaying && isCurrentVideo,
              onTap: () => _playVideoAudio(index),
              onPlayAudio: () => _playVideoAudio(index),
            );
          },
        );
      },
    );
  }

  Future<void> _playVideoAudio(int index) async {
    try {
      final videoFile = widget.videoFiles[index];
      final isCurrentVideo = _videoService.currentVideo?.path == videoFile.path;
      final isPlaying = _videoService.audioPlayer.playing;
      
      if (isCurrentVideo && isPlaying) {
        // Pause if currently playing
        await _videoService.pause();
      } else if (isCurrentVideo && !isPlaying) {
        // Resume if paused
        await _videoService.play();
      } else {
        // Play new video audio
        await _videoService.playVideo(index);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing video audio: $e'),
            backgroundColor: AppColor.primaryGreen,
          ),
        );
      }
    }
  }

  void _playVideo(MediaFile videoFile) {
    //Show video player options
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              videoFile.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.headphones, color: AppColor.primaryGreen),
              title: const Text(
                'Play Audio Only',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Extract and play audio from video',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                _playVideoAudio(widget.videoFiles.indexOf(videoFile));
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.play_circle, color: AppColor.primaryGreen),
            //   title: const Text(
            //     'Play Video',
            //     style: TextStyle(color: Colors.white),
            //   ),
            //   subtitle: const Text(
            //     'Full video player (coming soon)',
            //     style: TextStyle(color: Colors.grey),
            //   ),
            //   onTap: () {
            //     Navigator.pop(context);
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(
            //         content: Text('Full video player coming soon!'),
            //         backgroundColor: AppColor.primaryGreen,
            //       ),
            //     );
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.info_outline, color: Colors.grey),
            //   title: const Text(
            //     'File Info',
            //     style: TextStyle(color: Colors.white),
            //   ),
            //   subtitle: Text(
            //     '${videoFile.fileExtension} • ${videoFile.formattedSize}',
            //     style: const TextStyle(color: Colors.grey),
            //   ),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _showFileInfo(videoFile);
            //   },
            // ),
          ],
       ),
      ),
    );
  }

  void _showFileInfo(MediaFile videoFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'File Information',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name:', videoFile.displayName),
            _buildInfoRow('Type:', videoFile.fileExtension),
            _buildInfoRow('Size:', videoFile.formattedSize),
            _buildInfoRow('Path:', videoFile.path),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColor.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
