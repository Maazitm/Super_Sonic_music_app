import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:super_sonic/modal/media_file.dart';


class VideoThumbnailService {
  static final Map<String, String> _thumbnailCache = {};
  
  Future<String?> generateVideoThumbnail(MediaFile videoFile) async {
    // Check cache first
    if (_thumbnailCache.containsKey(videoFile.path)) {
      return _thumbnailCache[videoFile.path];
    }

    try {
      final thumbnailDir = await _getThumbnailDirectory();
      final thumbnailFileName = '${path.basenameWithoutExtension(videoFile.name)}_video_thumb.jpg';
      final thumbnailPath = path.join(thumbnailDir.path, thumbnailFileName);
      
      // Check if thumbnail already exists
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        _thumbnailCache[videoFile.path] = thumbnailPath;
        return thumbnailPath;
      }

      // Generate video thumbnail
      final generatedPath = await _generateVideoFrame(videoFile, thumbnailPath);

      if (generatedPath != null) {
        _thumbnailCache[videoFile.path] = generatedPath;
      }
      
      return generatedPath;
    } catch (e) {
      print('Error generating video thumbnail for ${videoFile.path}: $e');
      return null;
    }
  }

  Future<Directory> _getThumbnailDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final thumbnailDir = Directory(path.join(appDir.path, 'video_thumbnails'));
    
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }
    
    return thumbnailDir;
  }

  Future<String?> _generateVideoFrame(MediaFile videoFile, String thumbnailPath) async {
    try {
      // This is a placeholder implementation
      // In a real app, you would use a video processing library like:
      // - video_thumbnail package
      // - ffmpeg_kit_flutter package
      // - native platform channels
      
      final thumbnailFile = File(thumbnailPath);
      
      // Create a placeholder thumbnail file
      // In production, you'd extract an actual frame from the video
      await _createVideoThumbnailPlaceholder(thumbnailFile, videoFile);
      
      return thumbnailPath;
    } catch (e) {
      print('Error generating video frame: $e');
      return null;
    }
  }

  Future<void> _createVideoThumbnailPlaceholder(File file, MediaFile videoFile) async {
    // This creates a placeholder - in production you'd extract actual video frames
    await file.writeAsString('video_thumbnail_${videoFile.name}');
  }

  Widget buildVideoThumbnailWidget(MediaFile videoFile, {double size = 50}) {
    return FutureBuilder<String?>(
      future: generateVideoThumbnail(videoFile),
      builder: (context, snapshot) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red[700]!,
                Colors.red[900]!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video icon background
              Icon(
                Icons.movie,
                color: Colors.white.withOpacity(0.3),
                size: size * 0.6,
              ),
              // Play button overlay
              Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.red[700],
                  size: size * 0.2,
                ),
              ),
              // Duration badge (if available)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getVideoDurationText(videoFile),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getVideoDurationText(MediaFile videoFile) {
    // This is a placeholder - in production you'd extract actual video duration
    final extensions = ['.mp4', '.avi', '.mkv', '.mov'];
    if (extensions.contains(videoFile.extension.toLowerCase())) {
      return '${(videoFile.size / (1024 * 1024)).toStringAsFixed(0)}MB';
    }
    return videoFile.fileExtension;
  }

  void clearCache() {
    _thumbnailCache.clear();
  }
}
