import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:super_sonic/Appcolor/colors.dart';
import 'package:super_sonic/modal/media_file.dart';


class ThumbnailService {
  static final Map<String, String> _thumbnailCache = {};
  
  Future<String?> generateThumbnail(MediaFile mediaFile) async {
    // Check cache first
    if (_thumbnailCache.containsKey(mediaFile.path)) {
      return _thumbnailCache[mediaFile.path];
    }

    try {
      final thumbnailDir = await _getThumbnailDirectory();
      final thumbnailFileName = '${path.basenameWithoutExtension(mediaFile.name)}_thumb.jpg';
      final thumbnailPath = path.join(thumbnailDir.path, thumbnailFileName);
      
      // Check if thumbnail already exists
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        _thumbnailCache[mediaFile.path] = thumbnailPath;
        return thumbnailPath;
      }

      // Generate thumbnail based on media type
      String? generatedPath;
      if (mediaFile.type == MediaType.audio) {
        generatedPath = await _generateAudioThumbnail(mediaFile, thumbnailPath);
      } else {
        generatedPath = await _generateVideoThumbnail(mediaFile, thumbnailPath);
      }

      if (generatedPath != null) {
        _thumbnailCache[mediaFile.path] = generatedPath;
      }
      
      return generatedPath;
    } catch (e) {
      print('Error generating thumbnail for ${mediaFile.path}: $e');
      return null;
    }
  }

  Future<Directory> _getThumbnailDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final thumbnailDir = Directory(path.join(appDir.path, 'thumbnails'));
    
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }
    
    return thumbnailDir;
  }

  Future<String?> _generateAudioThumbnail(MediaFile mediaFile, String thumbnailPath) async {
    try {
      // For audio files, we'll create a default music icon thumbnail
      // In a real app, you might want to extract album art from the audio file
      final thumbnailFile = File(thumbnailPath);
      
      // Create a simple colored thumbnail based on the first letter of the song
      final firstLetter = mediaFile.displayName.isNotEmpty 
          ? mediaFile.displayName[0].toUpperCase() 
          : 'M';
      
      // Generate a simple thumbnail (this is a placeholder - you'd want to use a proper image library)
      await _createDefaultAudioThumbnail(thumbnailFile, firstLetter);
      
      return thumbnailPath;
    } catch (e) {
      print('Error generating audio thumbnail: $e');
      return null;
    }
  }

  Future<String?> _generateVideoThumbnail(MediaFile mediaFile, String thumbnailPath) async {
    try {
      // For video files, we'll create a default video icon thumbnail
      // In a real app, you'd want to extract a frame from the video
      final thumbnailFile = File(thumbnailPath);
      
      // Generate a simple thumbnail (this is a placeholder)
      await _createDefaultVideoThumbnail(thumbnailFile);
      
      return thumbnailPath;
    } catch (e) {
      print('Error generating video thumbnail: $e');
      return null;
    }
  }

  Future<void> _createDefaultAudioThumbnail(File file, String letter) async {
    // This is a placeholder - in a real app, you'd use a proper image generation library
    // For now, we'll just create an empty file to represent the thumbnail
    await file.writeAsString('audio_thumbnail_$letter');
  }

  Future<void> _createDefaultVideoThumbnail(File file) async {
    // This is a placeholder - in a real app, you'd use a proper video thumbnail extraction library
    await file.writeAsString('video_thumbnail');
  }

  Widget buildThumbnailWidget(MediaFile mediaFile, {double size = 50}) {
    return FutureBuilder<String?>(
      future: generateThumbnail(mediaFile),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // In a real app, you'd display the actual thumbnail image
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: mediaFile.type == MediaType.audio 
                  ? const Color(0xFF1DB954)
                  :  AppColor.primaryGreen,
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: mediaFile.type == MediaType.audio
                    ? [ Color(0xFF1DB954),  Color(0xFF1ED760)]
                    : [ AppColor.primaryGreen!,  AppColor.primaryGreen!],
              ),
            ),
            child: Icon(
              mediaFile.type == MediaType.audio 
                  ? Icons.music_note
                  : Icons.play_arrow,
              color: Colors.white,
              size: size * 0.5,
            ),
          );
        }
        
        // Default thumbnail while loading
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            mediaFile.type == MediaType.audio 
                ? Icons.music_note
                : Icons.videocam,
            color: Colors.white54,
            size: size * 0.5,
          ),
        );
      },
    );
  }

  void clearCache() {
    _thumbnailCache.clear();
  }
}
