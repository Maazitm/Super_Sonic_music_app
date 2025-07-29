import 'dart:io';

enum MediaType { audio, video }

class MediaFile {
  final String path;
  final String name;
  final String displayName;
  final String artist;
  final MediaType type;
  final String extension;
  final int size;
  final DateTime lastModified;
  String? thumbnailPath;

  MediaFile({
    required this.path,
    required this.name,
    required this.displayName,
    required this.artist,
    required this.type,
    required this.extension,
    required this.size,
    required this.lastModified,
    this.thumbnailPath,
  });

  factory MediaFile.fromFile(File file, MediaType type) {
    final fileName = file.uri.pathSegments.last;
    final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
    final extension = fileName.substring(fileName.lastIndexOf('.'));
    
    String displayName = nameWithoutExt;
    String artist = 'Unknown Artist';
    
    // Try to extract artist and song name from filename
    if (nameWithoutExt.contains(' - ')) {
      final parts = nameWithoutExt.split(' - ');
      if (parts.length >= 2) {
        artist = parts[0].trim();
        displayName = parts.sublist(1).join(' - ').trim();
      }
    }

    return MediaFile(
      path: file.path,
      name: fileName,
      displayName: displayName,
      artist: artist,
      type: type,
      extension: extension,
      size: 0, // Will be set later
      lastModified: DateTime.now(), // Will be set later
    );
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get fileExtension => extension.toUpperCase().substring(1);
}
