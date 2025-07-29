import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:super_sonic/Appcolor/colors.dart';
import 'package:super_sonic/services/video_thumnail.dart';
import '../services/video_service.dart';
import '../utils/theme.dart';

class VideoBottomPlayer extends StatelessWidget {
  const VideoBottomPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final videoService = VideoService();
    final thumbnailService = VideoThumbnailService();
    
    return StreamBuilder<PlayerState>(
      stream: videoService.audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final currentVideo = videoService.currentVideo;
        if (currentVideo == null) return const SizedBox.shrink();
        
        return Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColor.primaryGreen,
                AppTheme.cardBackground,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Progress Bar
              StreamBuilder<Duration>(
                stream: videoService.audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: videoService.audioPlayer.durationStream,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              activeTrackColor:  AppColor.primaryGreen,
                              inactiveTrackColor: Colors.grey[600],
                              thumbColor:  AppColor.primaryGreen,
                            ),
                            child: Slider(
                              value: duration.inMilliseconds > 0
                                  ? position.inMilliseconds.toDouble()
                                  : 0.0,
                              min: 0,
                              max: duration.inMilliseconds.toDouble(),
                              onChanged: duration.inMilliseconds > 0
                                  ? (value) async {
                                      await videoService.seek(
                                        Duration(milliseconds: value.toInt()),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              // Video Info and Controls
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Video Thumbnail
                      thumbnailService.buildVideoThumbnailWidget(
                        currentVideo, 
                        size: 50,
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Video Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentVideo.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.headphones,
                                  color: AppColor.primaryGreen,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Audio from ${currentVideo.fileExtension}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:  AppColor.primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Control Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: videoService.videoPlaylist.length > 1 
                                ? () => videoService.playPrevious() 
                                : null,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color:  AppColor.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                (snapshot.data?.playing ?? false) 
                                    ? Icons.pause 
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                if (snapshot.data?.playing ?? false) {
                                  videoService.pause();
                                } else {
                                  videoService.play();
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: videoService.videoPlaylist.length > 1 
                                ? () => videoService.playNext() 
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}
