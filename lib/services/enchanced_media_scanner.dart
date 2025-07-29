import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:super_sonic/modal/media_file.dart';


class EnhancedMediaScanner {
  static const List<String> audioExtensions = [
    '.mp3', '.m4a', '.wav', '.ogg', '.aac', '.flac', '.wma', '.opus', 
    '.3gp', '.amr', '.mp2', '.m4b', '.m4p', '.ra', '.rm', '.wv', '.ape'
  ];
  
  static const List<String> videoExtensions = [
    '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.3gp', 
    '.m4v', '.ts', '.mpg', '.mpeg', '.divx', '.xvid', '.rmvb', '.asf'
  ];

  /// Performs a comprehensive scan using multiple strategies
  static Future<List<MediaFile>> comprehensiveScan({
    Function(String)? onStatusUpdate,
    Function(int, int)? onProgress,
  }) async {
    final Set<MediaFile> allFiles = {};
    
    // Strategy 1: Standard directory scanning
    onStatusUpdate?.call('Scanning standard directories...');
    final standardFiles = await _scanStandardDirectories(onStatusUpdate);
    allFiles.addAll(standardFiles);
    
    // Strategy 2: File system traversal
    onStatusUpdate?.call('Performing file system traversal...');
    final traversalFiles = await _fileSystemTraversal(onStatusUpdate);
    allFiles.addAll(traversalFiles);
    
    // Strategy 3: Common file locations
    onStatusUpdate?.call('Checking common file locations...');
    final commonFiles = await _scanCommonLocations(onStatusUpdate);
    allFiles.addAll(commonFiles);
    
    // Strategy 4: App-specific directories
    onStatusUpdate?.call('Scanning app-specific directories...');
    final appFiles = await _scanAppDirectories(onStatusUpdate);
    allFiles.addAll(appFiles);
    
    final finalList = allFiles.toList();
    finalList.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    
    final audioCount = finalList.where((f) => f.type == MediaType.audio).length;
    final videoCount = finalList.where((f) => f.type == MediaType.video).length;
    
    onStatusUpdate?.call('Enhanced scan complete: $audioCount audio, $videoCount video files');
    
    return finalList;
  }

  static Future<List<MediaFile>> _scanStandardDirectories(Function(String)? onStatusUpdate) async {
    final List<MediaFile> files = [];
    
    final standardDirs = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/Audio',
      '/storage/emulated/0/Sounds',
      '/storage/emulated/0/Media',
      '/sdcard/Music',
      '/sdcard/Download',
      '/sdcard/Downloads',
      '/sdcard/DCIM',
      '/sdcard/Movies',
    ];
    
    for (final dirPath in standardDirs) {
      try {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          final dirFiles = await _scanDirectoryRecursive(dir);
          files.addAll(dirFiles);
          onStatusUpdate?.call('Scanned ${path.basename(dirPath)}: ${dirFiles.length} files');
        }
      } catch (e) {
        print('Error scanning $dirPath: $e');
      }
    }
    
    return files;
  }

  static Future<List<MediaFile>> _fileSystemTraversal(Function(String)? onStatusUpdate) async {
    final List<MediaFile> files = [];
    
    // Traverse from root storage
    final rootDirs = ['/storage/emulated/0', '/sdcard'];
    
    for (final rootPath in rootDirs) {
      try {
        final rootDir = Directory(rootPath);
        if (await rootDir.exists()) {
          await _traverseDirectory(rootDir, files, maxDepth: 4);
        }
      } catch (e) {
        print('Error traversing $rootPath: $e');
      }
    }
    
    return files;
  }

  static Future<void> _traverseDirectory(Directory dir, List<MediaFile> files, {int maxDepth = 4, int currentDepth = 0}) async {
    if (currentDepth >= maxDepth) return;
    
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          final mediaFile = await _createMediaFileIfValid(entity);
          if (mediaFile != null && !files.any((f) => f.path == mediaFile.path)) {
            files.add(mediaFile);
          }
        } else if (entity is Directory) {
          final dirName = path.basename(entity.path).toLowerCase();
          if (!_isSystemDirectory(dirName)) {
            await _traverseDirectory(entity, files, maxDepth: maxDepth, currentDepth: currentDepth + 1);
          }
        }
      }
    } catch (e) {
      // Skip inaccessible directories
      return;
    }
  }

  static Future<List<MediaFile>> _scanCommonLocations(Function(String)? onStatusUpdate) async {
    final List<MediaFile> files = [];
    
    // Common locations where users store media files
    final commonPaths = [
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Video',
      '/storage/emulated/0/Telegram',
      '/storage/emulated/0/Bluetooth',
      '/storage/emulated/0/Recordings',
      '/storage/emulated/0/Voice Recorder',
      '/storage/emulated/0/SoundRecorder',
      '/storage/emulated/0/Call Recordings',
      '/storage/emulated/0/Ringtones',
      '/storage/emulated/0/Notifications',
      '/storage/emulated/0/Alarms',
      '/storage/emulated/0/Podcasts',
      '/storage/emulated/0/Audiobooks',
    ];
    
    for (final dirPath in commonPaths) {
      try {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          final dirFiles = await _scanDirectoryRecursive(dir);
          files.addAll(dirFiles);
        }
      } catch (e) {
        print('Error scanning common location $dirPath: $e');
      }
    }
    
    return files;
  }

  static Future<List<MediaFile>> _scanAppDirectories(Function(String)? onStatusUpdate) async {
    final List<MediaFile> files = [];
    
    // App-specific directories
    final appDirs = [
      '/storage/emulated/0/Android/data',
      '/storage/emulated/0/Android/media',
    ];
    
    for (final appDirPath in appDirs) {
      try {
        final appDir = Directory(appDirPath);
        if (await appDir.exists()) {
          await for (final entity in appDir.list()) {
            if (entity is Directory) {
              // Look for media files in app directories
              final appFiles = await _scanDirectoryRecursive(entity, maxDepth: 3);
              files.addAll(appFiles);
            }
          }
        }
      } catch (e) {
        print('Error scanning app directory $appDirPath: $e');
      }
    }
    
    return files;
  }

  static Future<List<MediaFile>> _scanDirectoryRecursive(Directory directory, {int maxDepth = 10}) async {
    final List<MediaFile> files = [];
    
    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final mediaFile = await _createMediaFileIfValid(entity);
          if (mediaFile != null) {
            files.add(mediaFile);
          }
        }
      }
    } catch (e) {
      print('Error scanning directory recursively ${directory.path}: $e');
    }
    
    return files;
  }

  static Future<MediaFile?> _createMediaFileIfValid(File file) async {
    try {
      final fileName = file.path.toLowerCase();
      final isAudio = audioExtensions.any((ext) => fileName.endsWith(ext));
      final isVideo = videoExtensions.any((ext) => fileName.endsWith(ext));
      
      if (isAudio || isVideo) {
        final stat = await file.stat();
        if (stat.size > 1024) { // At least 1KB
          final mediaType = isAudio ? MediaType.audio : MediaType.video;
          final mediaFile = MediaFile.fromFile(file, mediaType);
          return MediaFile(
            path: mediaFile.path,
            name: mediaFile.name,
            displayName: mediaFile.displayName,
            artist: mediaFile.artist,
            type: mediaFile.type,
            extension: mediaFile.extension,
            size: stat.size,
            lastModified: stat.modified,
          );
        }
      }
    } catch (e) {
      // Skip files that can't be accessed
      return null;
    }
    
    return null;
  }

  static bool _isSystemDirectory(String dirName) {
    final systemDirs = [
      'android', 'system', 'proc', 'sys', 'dev', 'cache', 'tmp',
      '.android_secure', '.thumbnails', '.trash', 'lost+found',
      'android_secure', 'clockworkmod', 'recovery', 'boot',
      '.nomedia', '.temp', '.cache', '.system', '.data', '.git',
      'node_modules', '.gradle', '.idea', 'build'
    ];
    
    return systemDirs.any((sysDir) => dirName.contains(sysDir));
  }
}
