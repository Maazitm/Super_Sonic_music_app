import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:super_sonic/Appcolor/colors.dart';
import 'package:super_sonic/modal/media_file.dart';
import 'package:super_sonic/services/video_thumnail.dart';
import '../services/video_service.dart';
import '../utils/theme.dart';

class VideoListTile extends StatelessWidget {
  final MediaFile videoFile;
  final bool isCurrentVideo;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onPlayAudio;

  const VideoListTile({
    super.key,
    required this.videoFile,
    required this.isCurrentVideo,
    required this.isPlaying,
    required this.onTap,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailService = VideoThumbnailService();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentVideo 
            ? Colors.red.withOpacity(0.1)
            : Colors.grey[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentVideo 
            ? Border.all(color: Colors.red.withOpacity(0.5), width: 1)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: thumbnailService.buildVideoThumbnailWidget(videoFile, size: 60),
        title: Text(
          videoFile.displayName,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: TextStyle(
            fontWeight: isCurrentVideo ? FontWeight.bold : FontWeight.w500,
            color: isCurrentVideo ?  AppColor.primaryGreen : Colors.white,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              videoFile.artist != 'Unknown Artist' 
                  ? videoFile.artist 
                  : 'Video File',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  videoFile.fileExtension,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' • ${videoFile.formattedSize}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                if (isCurrentVideo && isPlaying)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:  AppColor.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Playing Audio',
                      style: TextStyle(
                        color:  Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Audio play button
            IconButton(
              icon: Icon(
                isCurrentVideo && isPlaying 
                    ? Icons.pause_circle_filled 
                    : Icons.headphones,
                color: isCurrentVideo 
                    ?  AppColor.primaryGreen
                    : Colors.grey[600],
                size: 28,
              ),
              onPressed: onPlayAudio,
              tooltip: 'Play Audio',
            ),
            // Video play button
            IconButton(
              icon: Icon(
                Icons.play_circle_outline,
                color:  AppColor.primaryGreen,
                size: 32,
              ),
              onPressed: onTap,
              tooltip: 'Play Video',
            ),
          ],
        ),
      ),
    );
  }
}
