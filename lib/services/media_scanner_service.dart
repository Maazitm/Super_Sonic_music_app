import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:super_sonic/modal/media_file.dart';


class MediaScannerService {
  static const List<String> audioExtensions = [
    '.mp3', '.m4a', '.wav', '.ogg', '.aac', '.flac', '.wma', '.opus'
  ];
  
  static const List<String> videoExtensions = [
    '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.3gp'
  ];

  Future<bool> requestPermissions() async {
    try {
      bool permissionGranted = false;
      
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        Map<Permission, PermissionStatus> permissions = {};
        
        if (sdkInt >= 33) {
          permissions = await [
            Permission.audio,
            Permission.videos,
            Permission.manageExternalStorage,
            Permission.storage,
          ].request();
        } else if (sdkInt >= 30) {
          permissions = await [
            Permission.manageExternalStorage,
            Permission.storage,
          ].request();
        } else {
          permissions = await [
            Permission.storage,
          ].request();
        }
        
        permissionGranted = permissions.values.any((status) => status.isGranted);
      } else {
        final mediaPermission = await Permission.mediaLibrary.request();
        permissionGranted = mediaPermission.isGranted;
      }

      return permissionGranted;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  Future<List<MediaFile>> scanMediaFiles({
    Function(String)? onStatusUpdate,
    Function(int, int)? onProgress,
  }) async {
    final List<MediaFile> allMediaFiles = [];
    
    onStatusUpdate?.call('Scanning for media files...');
    
    try {
      if (Platform.isAndroid) {
        final directories = await _getAndroidDirectories();
        
        int currentDir = 0;
        for (final dirPath in directories) {
          currentDir++;
          onProgress?.call(currentDir, directories.length);
          
          final dir = Directory(dirPath);
          try {
            if (await dir.exists()) {
              onStatusUpdate?.call('Scanning: ${dir.path.split('/').last}');
              
              final audioFiles = await _findMediaFiles(dir, audioExtensions, MediaType.audio);
              final videoFiles = await _findMediaFiles(dir, videoExtensions, MediaType.video);
              
              allMediaFiles.addAll(audioFiles);
              allMediaFiles.addAll(videoFiles);
              
              onStatusUpdate?.call('Found ${allMediaFiles.length} media files...');
            }
          } catch (e) {
            print('Error scanning directory $dirPath: $e');
          }
        }
      } else {
        // iOS scanning
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          final audioFiles = await _findMediaFiles(appDocDir, audioExtensions, MediaType.audio);
          final videoFiles = await _findMediaFiles(appDocDir, videoExtensions, MediaType.video);
          allMediaFiles.addAll(audioFiles);
          allMediaFiles.addAll(videoFiles);
        } catch (e) {
          print('Error scanning iOS directories: $e');
        }
      }

      // Remove duplicates and sort
      final uniqueFiles = <String, MediaFile>{};
      for (final file in allMediaFiles) {
        uniqueFiles[file.path] = file;
      }
      
      final sortedFiles = uniqueFiles.values.toList();
      sortedFiles.sort((a, b) => a.displayName.toLowerCase()
          .compareTo(b.displayName.toLowerCase()));

      onStatusUpdate?.call('Found ${sortedFiles.length} media files');
      return sortedFiles;
    } catch (e) {
      onStatusUpdate?.call('Error scanning files: $e');
      print('Scan error: $e');
      return [];
    }
  }

  Future<Set<String>> _getAndroidDirectories() async {
    final Set<String> directories = {
      '/storage/emulated/0',
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Podcasts',
      '/storage/emulated/0/Ringtones',
      '/storage/emulated/0/Notifications',
      '/storage/emulated/0/Alarms',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Video',
      '/storage/emulated/0/Telegram',
      '/sdcard',
      '/sdcard/Music',
      '/sdcard/Download',
      '/sdcard/Downloads',
      '/sdcard/Movies',
    };
    
    // Add external storage directories
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        directories.addAll([
          externalDir.path,
          '${externalDir.parent.path}/Music',
          '${externalDir.parent.path}/Download',
          '${externalDir.parent.path}/Movies',
        ]);
      }
    } catch (e) {
      print('Could not get external storage directory: $e');
    }

    try {
      final List<Directory> externalDirs = await getExternalStorageDirectories() ?? [];
      for (final dir in externalDirs) {
        directories.addAll([
          dir.path,
          '${dir.parent.path}/Music',
          '${dir.parent.path}/Download',
          '${dir.parent.path}/Movies',
        ]);
      }
    } catch (e) {
      print('Error getting external directories: $e');
    }

    return directories;
  }

  Future<List<MediaFile>> _findMediaFiles(
      Directory directory, List<String> extensions, MediaType type) async {
    final List<MediaFile> mediaFiles = [];
    
    try {
      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true, followLinks: false)) {
          try {
            if (entity is File) {
              final fileName = entity.path.toLowerCase();
              if (extensions.any((ext) => fileName.endsWith(ext))) {
                final stat = await entity.stat();
                if (stat.size > 1024) { // At least 1KB
                  final mediaFile = MediaFile.fromFile(entity, type);
                  // Set file stats
                  final updatedFile = MediaFile(
                    path: mediaFile.path,
                    name: mediaFile.name,
                    displayName: mediaFile.displayName,
                    artist: mediaFile.artist,
                    type: mediaFile.type,
                    extension: mediaFile.extension,
                    size: stat.size,
                    lastModified: stat.modified,
                  );
                  mediaFiles.add(updatedFile);
                  print('Found ${type.name} file: ${entity.path}');
                }
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      print('Error accessing directory ${directory.path}: $e');
    }
    
    return mediaFiles;
  }
}
