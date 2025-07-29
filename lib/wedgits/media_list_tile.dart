import 'package:flutter/material.dart';
import 'package:super_sonic/modal/media_file.dart';
import 'package:super_sonic/services/thumnail_services.dart';
import '../utils/theme.dart';

class MediaListTile extends StatelessWidget {
  final MediaFile mediaFile;
  final bool isCurrentTrack;
  final bool isPlaying;
  final VoidCallback onTap;

  const MediaListTile({
    super.key,
    required this.mediaFile,
    required this.isCurrentTrack,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailService = ThumbnailService();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrentTrack 
            ? AppTheme.primaryGreen.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: thumbnailService.buildThumbnailWidget(mediaFile, size: 50),
        title: Text(
          mediaFile.displayName,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
            color: isCurrentTrack ? AppTheme.primaryGreen : Colors.white,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mediaFile.artist,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            if (mediaFile.type == MediaType.video)
              Text(
                '${mediaFile.fileExtension} • ${mediaFile.formattedSize}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: _buildTrailingIcon(),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTrailingIcon() {
    if (mediaFile.type == MediaType.audio) {
      if (isCurrentTrack) {
        return Icon(
          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
          color: AppTheme.primaryGreen,
          size: 32,
        );
      } else {
        return Icon(
          Icons.play_circle_outline,
          color: Colors.grey[600],
          size: 32,
        );
      }
    } else {
      return Icon(
        Icons.play_circle_outline,
        color: Colors.red[400],
        size: 32,
      );
    }
  }
}
